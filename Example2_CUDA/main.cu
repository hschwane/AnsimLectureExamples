#include "mpUtils/mpUtils.h"
#include "mpUtils/mpGraphics.h"
#include "mpUtils/mpCuda.h"
#include "SimplexNoise.h"

#include "../particleRenderer/ParticleRenderer.h"
#include <random>

constexpr int wgsize = 256; // cuda work group size

void generateInitialConditions(std::vector<float4>& pos, std::vector<float4>& vel, std::vector<float4>& acc, int particleCount, int simulationMode) {
    std::random_device rd;
    std::default_random_engine rng(rd());

    pos.resize(particleCount);
    vel.resize(particleCount);
    acc.resize(particleCount);

    if(simulationMode == 0) { // spawn particles in a sphere with initial velocity
        std::uniform_real_distribution<float> dist(0.0f,1.0f);
        SimplexNoise simplexGenerator(0.6);
        for(int i = 0; i<particleCount; i++) {
            mpu::randUniformSphere(dist(rng),dist(rng),dist(rng), 1.0f, pos[i].x, pos[i].y, pos[i].z);

            vel[i] = make_float4(0,0,0,0);
            vel[i] += make_float4( cross(make_float3(pos[i]), make_float3(0,1.1,0)), 0);

            vel[i].x += 0.15f*simplexGenerator.fractal(3,pos[i].x,pos[i].y,pos[i].z);
            vel[i].y += 0.15f*simplexGenerator.fractal(3,pos[i].x+500,pos[i].y+500,pos[i].z+500);
            vel[i].z += 0.15f*simplexGenerator.fractal(3,pos[i].x-500,pos[i].y-500,pos[i].z-500);
        }
    } else if(simulationMode == 1) { // spawn particles in a rotating disc
        std::uniform_real_distribution<float> dist(0.0f,1.0f);
        for(int i = 0; i<particleCount; i++) {

            mpu::randUniformSphere(dist(rng),dist(rng),dist(rng), 2.0f, pos[i].x, pos[i].y, pos[i].z);
            while( length(pos[i]) < 0.4 || pos[i].y > 0.05 || pos[i].y < -0.05) {
                mpu::randUniformSphere(dist(rng),dist(rng),dist(rng), 2.0f, pos[i].x, pos[i].y, pos[i].z);
            }

            float3 direction = normalize( cross( make_float3(pos[i]), make_float3(0,1,0)));
            float v = sqrt( 50 / length(pos[i]));

            vel[i] = v * make_float4(direction,0);
        }
    }
}

__device__ float3 calcGravity(float3 posi, float3 posj, float epsilon2) {
    float3 rvec = posj - posi;
    float r2 = rvec.x*rvec.x + rvec.y*rvec.y + rvec.z*rvec.z + epsilon2;
    float r2e = r2 + epsilon2;
    float distSixth = r2e * r2e * r2e;
    float invDistCube = rsqrt(distSixth);
    return invDistCube * rvec;
}

__global__ void calcAcceleration(float4* pos, float4* vel, float4* acc, int particleCount, float epsilon2, int simulationMode)
{
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if(i > particleCount)
        return;

    float3 posi = make_float3(pos[i]);
    float3 acci{0,0,0};

    for(int j=0; j<particleCount; j++) {
        float3 posj = make_float3(pos[j]);
        acci += calcGravity(posi,posj,epsilon2);
    }

    acci *= 1.0f/particleCount;
    if(simulationMode == 1) { // mode 1 means we have an accretion disk around a central body
        acci += 50*calcGravity(posi, float3{0,0,0}, epsilon2);
    }
    acc[i] = float4{acci.x,acci.y,acci.z,0};
}

__global__ void integrateLeapfrog(float4* pos, float4* vel, float4* acc, int particleCount, float dt)
{
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if(i > particleCount)
        return;

    pos[i] = pos[i] + vel[i] * dt;
    vel[i] = vel[i] + acc[i] * dt;
}

__global__ void initializeLeapfrog(float4* pos, float4* vel, float4* acc, int particleCount, float dt)
{
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if(i > particleCount)
        return;

    vel[i] = vel[i] + acc[i] * dt*0.5f;
}

void showSettingsWindow(int& particleCount, bool& isSimRunning, float& dt, float& simulatedTime, int& simulationMode, float& epsilon2,
                        std::vector<float4>& pos, std::vector<float4>& vel, std::vector<float4>& acc,
                        mpu::gph::Buffer<float4>& posBuffer, mpu::gph::Buffer<float4>& velBuffer,
                        mpu::gph::Buffer<float4>& accBuffer, mpu::GlBufferMapper<float4>& posMapper,
                        mpu::GlBufferMapper<float4>& velMapper, mpu::GlBufferMapper<float4>& accMapper,
                        ParticleRenderer& renderer)
{
    static std::once_flag onceFlag;
    static unsigned int uiParticleCount;
    static int uiSimulationMode;
    std::call_once(onceFlag, [&](){
       uiParticleCount = particleCount;
        uiSimulationMode = simulationMode;
    });

    using namespace mpu::gph;
    if(ImGui::Begin("Simulation"))
    {
        ImGui::Text("Simulated Time: %f units", simulatedTime);
        ImGui::DragFloat("DeltaT", &dt, 0.00005,0.0001,1.0,"%.4f");
        ImGui::ToggleButton("RunSimulation", &isSimRunning);

        ImGui::PushID("InitialConditions");
        if(ImGui::CollapsingHeader("Rendering Mode"))
        {
            ImGui::Text("Particles: %i",uiParticleCount);
            ImGui::SameLine();
            if (ImGui::Button("-")) {
                uiParticleCount = uiParticleCount >> 1;
            }
            ImGui::SameLine();
            if(ImGui::Button("+")) {
                uiParticleCount = uiParticleCount << 1;
            }

            ImGui::Combo("Mode",&uiSimulationMode,"Sphere\0Disk\0\0");

            if(ImGui::Button("Reset Simulation"))
            {
                simulatedTime = 0;
                isSimRunning = false;
                particleCount = uiParticleCount;
                simulationMode = uiSimulationMode;

                generateInitialConditions( pos, vel, acc, particleCount, simulationMode);
                posBuffer = mpu::gph::Buffer<float4>(pos);
                velBuffer = mpu::gph::Buffer<float4>(vel);
                accBuffer = mpu::gph::Buffer<float4>(acc);

                posMapper = mpu::mapBufferToCuda(posBuffer);
                velMapper = mpu::mapBufferToCuda(velBuffer);
                accMapper = mpu::mapBufferToCuda(accBuffer);

                posMapper.map();
                velMapper.map();
                accMapper.map();

                calcAcceleration<<<ceil(posMapper.size()/float(wgsize)),wgsize>>>(posMapper.data(), velMapper.data(), accMapper.data(), posMapper.size(), epsilon2, simulationMode);
                initializeLeapfrog<<<ceil(posMapper.size()/float(wgsize)),wgsize>>>(posMapper.data(), velMapper.data(), accMapper.data(), posMapper.size(),dt);

                posMapper.unmap();
                velMapper.unmap();
                accMapper.unmap();

                renderer.setBuffers(posBuffer,velBuffer);
            }
        }

        ImGui::PopID();
    }
    ImGui::End();
}

int main()
{
    // Setup window
    // --------------------------
    mpu::Log myLog( mpu::LogLvl::ALL, mpu::ConsoleSink());
    myLog.printHeader("graphicsTest", MPU_VERSION_STRING, MPU_VERSION_COMMIT, "");

    int width = 800;
    int height = 600;
    mpu::gph::Window window(width, height,"AnSim Lecture Example");
    ImGui::create(window);
    mpu::gph::enableVsync(true);

    ParticleRenderer renderer;

    window.addFBSizeCallback([&](int width, int height)
    {
        glViewport(0,0,width,height);
        renderer.updateProjection(width,height);
    });
    renderer.updateProjection(width,height);
    // --------------------------

    // Setup simulation
    // --------------------------
    int particleCount = 512; // number of particles in the simulation
    float dt = 0.005; // timestep
    float simulatedTime = 0.0f; // simulated time since beginning of simulation
    bool isSimRunning = false; // is simulation running right now
    float epsilon2 = 0.0005; // smoothing factor epsilon^2
    int simulationMode = 0; // the type of initial condition used

    std::vector<float4> pos;
    std::vector<float4> vel;
    std::vector<float4> acc;
    generateInitialConditions( pos, vel, acc, particleCount, simulationMode);

    mpu::gph::Buffer<float4> posBuffer(pos);
    mpu::gph::Buffer<float4> velBuffer(vel);
    mpu::gph::Buffer<float4> accBuffer(acc);
    renderer.setBuffers(posBuffer,velBuffer);

    mpu::GlBufferMapper posMapper = mpu::mapBufferToCuda(posBuffer);
    mpu::GlBufferMapper velMapper = mpu::mapBufferToCuda(velBuffer);
    mpu::GlBufferMapper accMapper = mpu::mapBufferToCuda(accBuffer);

    posMapper.map();
    velMapper.map();
    accMapper.map();

    calcAcceleration<<<ceil(posMapper.size()/float(wgsize)),wgsize>>>(posMapper.data(), velMapper.data(), accMapper.data(), posMapper.size(), epsilon2, simulationMode);
    initializeLeapfrog<<<ceil(posMapper.size()/float(wgsize)),wgsize>>>(posMapper.data(), velMapper.data(), accMapper.data(), posMapper.size(),dt);

    posMapper.unmap();
    velMapper.unmap();
    accMapper.unmap();
    // --------------------------

    // setup keybinding to start / stop simulation with "F"
    // --------------------------
    mpu::gph::Input::addButton("ToggleSim","", [&](mpu::gph::Window& w){
        isSimRunning = !isSimRunning;
    });
    mpu::gph::Input::mapKeyToInput("ToggleSim", GLFW_KEY_F);
    // --------------------------

    while (window.frameEnd(), mpu::gph::Input::update(), window.frameBegin())
    {
        // run simulation here
        if(isSimRunning) {
            posMapper.map();
            velMapper.map();
            accMapper.map();

            calcAcceleration<<<ceil(posMapper.size()/float(wgsize)),wgsize>>>(posMapper.data(), velMapper.data(), accMapper.data(), posMapper.size(), epsilon2, simulationMode);
            integrateLeapfrog<<<ceil(posMapper.size()/float(wgsize)),wgsize>>>(posMapper.data(), velMapper.data(), accMapper.data(), posMapper.size(),dt);
            simulatedTime += dt;

            posMapper.unmap();
            velMapper.unmap();
            accMapper.unmap();
        }

        showSettingsWindow(particleCount,isSimRunning,dt,simulatedTime,simulationMode,epsilon2,
                           pos,vel,acc,posBuffer,velBuffer,accBuffer,posMapper,velMapper,accMapper,renderer);
        mpu::gph::showBasicPerformanceWindow();
        renderer.showGui();
        renderer.render();
    }

    return 0;
}
