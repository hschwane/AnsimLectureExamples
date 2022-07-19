/*
 * AnsimLectureExample
 * ParticleRenderer.cpp
 *
 * @author: Hendrik Schwanekamp
 * @mail:   hendrik.schwanekamp@gmx.net
 *
 * Implements the ParticleRenderer class
 *
 * Copyright (c) 2022 Hendrik Schwanekamp
 *
 */

// includes
//--------------------
#include "ParticleRenderer.h"
//--------------------

// namespace
//--------------------

//--------------------

// function definitions of the ParticleRenderer class
//-------------------------------------------------------------------

const std::string ParticleRenderer::colorModeToString[] = {"constant","velocity","speed"};

ParticleRenderer::ParticleRenderer()
{
    mpu::gph::addShaderIncludePath(MPU_LIB_SHADER_PATH"/include");
    mpu::gph::addShaderIncludePath(PROJECT_SHADER_PATH);
    m_particleShader = mpu::gph::ShaderProgram({{FRAG_SHADER_PATH},{VERT_SHADER_PATH},{GEOM_SHADER_PATH}});

    m_particleShader.uniform1f("sphereRadius", m_particleRadius);
    m_particleShader.uniformMat4("view", glm::mat4(1.0f));
    m_particleShader.uniformMat4("model", glm::mat4(1.0f));
    m_particleShader.uniformMat4("projection", glm::mat4(1.0f));
    m_particleShader.uniform3f("defaultColor", m_particleColor);
    m_particleShader.uniform1f("brightness", m_brightness);
    m_particleShader.uniform1f("materialAlpha", m_particleAlpha);
    m_particleShader.uniform1f("materialShininess", m_materialShininess);
    m_particleShader.uniform1ui("colorMode",static_cast<unsigned int>(m_colorMode));
    m_particleShader.uniform1f("upperBound", m_upperBound);
    m_particleShader.uniform1f("lowerBound", m_lowerBound);
    m_particleShader.uniform3f("light.position", m_lightPosition);
    m_particleShader.uniform3f("light.diffuse", m_lightDiffuse);
    m_particleShader.uniform3f("light.specular", m_lightSpecular);
    m_particleShader.uniform3f("ambientLight", m_lightAmbient);
    m_particleShader.uniform1b("lightInViewSpace", m_linkLightToCamera);
    m_particleShader.uniform1b("renderFlatDisks", m_renderFlatDisks);
    m_particleShader.uniform1b("flatFalloff", m_flatFalloff);
    m_particleShader.uniform1b("enableEdgeHighlights", m_enableEdgeHighlights);

    glClearColor( .1f, .1f, .1f, 1.0f);
    setBlending(m_additiveBlending);

    m_camera.setPosition({0,0,4});
    m_camera.setTarget({0,0,0});
    m_camera.setRotationSpeedFPS(0.0038);
    m_camera.setRotationSpeedTB(0.012);
    m_camera.setMode(mpu::gph::Camera::trackball);
    m_camera.addInputs();
    addKeybindings();

    m_vao.bind();
}

void ParticleRenderer::updateProjection(int width, int height)
{
    m_projection = glm::perspective(glm::radians(m_fieldOfFiew), float(width) / float(height), m_near, m_far);
    m_particleShader.uniformMat4("projection", m_projection);
}

void ParticleRenderer::render()
{
    m_camera.update();

    m_vao.bind();
    m_particleShader.use();
    m_particleShader.uniformMat4("view",m_camera.viewMatrix());
    glDrawArrays(GL_POINTS, 0, m_particleCount);
}

void ParticleRenderer::showGui()
{
    using namespace mpu::gph;
    if(ImGui::Begin("Rendering"))
    {
        ImGui::PushID("RenderingMode");
        if(ImGui::CollapsingHeader("Rendering Mode"))
        {
            if(ImGui::Checkbox("Additive Blending", &m_additiveBlending))
                setBlending(m_additiveBlending);

            if(ImGui::RadioButton("Sphere", !m_renderFlatDisks))
            {
                m_renderFlatDisks = false;
                m_particleShader.uniform1b("renderFlatDisks", m_renderFlatDisks);
            }
            ImGui::SameLine();
            if(ImGui::RadioButton("Disk", m_renderFlatDisks))
            {
                m_renderFlatDisks = true;
                m_particleShader.uniform1b("renderFlatDisks", m_renderFlatDisks);
            }

            if(m_renderFlatDisks)
            {
                if(ImGui::Checkbox("Falloff", &m_flatFalloff))
                    m_particleShader.uniform1b("flatFalloff", m_flatFalloff);
            }

            if(ImGui::Checkbox("Edge Highlights",&m_enableEdgeHighlights))
                m_particleShader.uniform1b("enableEdgeHighlights",m_enableEdgeHighlights);
        }

        ImGui::PopID();
        ImGui::PushID("ParticleProperties");

        if(ImGui::CollapsingHeader("Particle properties"))
        {
            if(ImGui::SliderFloat("Size", &m_particleRadius, 0.00001, 1, "%.5f",2.0f))
                m_particleShader.uniform1f("sphereRadius", m_particleRadius);

            const char* modes[] = {"constant","velocity","speed","density"};
            int selected = static_cast<int>(m_colorMode);
            if(ImGui::Combo("Color Mode", &selected, modes,numColorModes))
            {
                m_colorMode = static_cast<ColorMode>(selected);
                m_particleShader.uniform1ui("colorMode",static_cast<unsigned int>(m_colorMode));
            }

            if(m_colorMode == ColorMode::CONSTANT)
            {

                if(ImGui::ColorEdit3("Color", glm::value_ptr(m_particleColor)))
                    m_particleShader.uniform3f("defaultColor", m_particleColor);
            } else if(m_colorMode != ColorMode::VELOCITY)
            {
                if(ImGui::DragFloat("Upper Bound",&m_upperBound,0.01,0.0f,0.0f,"%.5f"))
                    m_particleShader.uniform1f("upperBound",m_upperBound);
                if(ImGui::DragFloat("Lower Bound",&m_lowerBound,0.01,0.0f,0.0f,"%.5f"))
                    m_particleShader.uniform1f("lowerBound",m_lowerBound);
            }

            if(ImGui::SliderFloat("Brightness", &m_brightness, 0, 1, "%.4f", 4.0f))
                m_particleShader.uniform1f("brightness", m_brightness);

            if(ImGui::SliderFloat("Shininess", &m_materialShininess, 0, 50))
                m_particleShader.uniform1f("materialShininess", m_materialShininess);
        }

        ImGui::PopID();
        ImGui::PushID("LightProperties");

        if(ImGui::CollapsingHeader("Light properties"))
        {
            if(ImGui::Checkbox("Move Light with Camera", &m_linkLightToCamera))
                m_particleShader.uniform1b("lightInViewSpace", m_linkLightToCamera);

            if(ImGui::DragFloat3("Position", glm::value_ptr(m_lightPosition)))
                m_particleShader.uniform3f("light.position", m_lightPosition);

            if(ImGui::ColorEdit3("Diffuse", glm::value_ptr(m_lightDiffuse)))
                m_particleShader.uniform3f("light.diffuse", m_lightDiffuse);

            if(ImGui::ColorEdit3("Specular", glm::value_ptr(m_lightSpecular)))
                m_particleShader.uniform3f("light.specular", m_lightSpecular);

            if(ImGui::ColorEdit3("Ambient", glm::value_ptr(m_lightAmbient)))
                m_particleShader.uniform3f("ambientLight", m_lightAmbient);
        }
        ImGui::PopID();
    }
    ImGui::End();
}

void ParticleRenderer::setBlending(bool additive)
{
    if(additive)
    {
        glBlendFunc(GL_ONE, GL_ONE);
        glEnable(GL_BLEND);
        glDisable(GL_DEPTH_TEST);
    }
    else
    {
        glDisable(GL_BLEND);
        glEnable(GL_DEPTH_TEST);
    }
}

void ParticleRenderer::addKeybindings()
{
    using namespace mpu::gph;

    // camera
    Input::mapKeyToInput("CameraMoveSideways",GLFW_KEY_D,Input::ButtonBehavior::whenDown,Input::AxisBehavior::positive);
    Input::mapKeyToInput("CameraMoveSideways",GLFW_KEY_A,Input::ButtonBehavior::whenDown,Input::AxisBehavior::negative);
    Input::mapKeyToInput("CameraMoveForwardBackward",GLFW_KEY_W,Input::ButtonBehavior::whenDown,Input::AxisBehavior::positive);
    Input::mapKeyToInput("CameraMoveForwardBackward",GLFW_KEY_S,Input::ButtonBehavior::whenDown,Input::AxisBehavior::negative);
    Input::mapKeyToInput("CameraMoveUpDown",GLFW_KEY_Q,Input::ButtonBehavior::whenDown,Input::AxisBehavior::negative);
    Input::mapKeyToInput("CameraMoveUpDown",GLFW_KEY_E,Input::ButtonBehavior::whenDown,Input::AxisBehavior::positive);

    Input::mapCourserToInput("CameraPanHorizontal", Input::AxisOrientation::horizontal,Input::AxisBehavior::negative,0, "EnablePan");
    Input::mapCourserToInput("CameraPanVertical", Input::AxisOrientation::vertical,Input::AxisBehavior::positive,0, "EnablePan");
    Input::mapScrollToInput("CameraZoom");

    Input::mapMouseButtonToInput("EnablePan", GLFW_MOUSE_BUTTON_MIDDLE);
    Input::mapKeyToInput("EnablePan", GLFW_KEY_LEFT_ALT);

    Input::mapCourserToInput("CameraRotateHorizontal", Input::AxisOrientation::horizontal,Input::AxisBehavior::negative,0, "EnableRotation");
    Input::mapCourserToInput("CameraRotateVertical", Input::AxisOrientation::vertical,Input::AxisBehavior::negative,0, "EnableRotation");

    Input::mapMouseButtonToInput("EnableRotation", GLFW_MOUSE_BUTTON_LEFT);
    Input::mapKeyToInput("EnableRotation", GLFW_KEY_LEFT_CONTROL);

    Input::mapKeyToInput("CameraMovementSpeed",GLFW_KEY_RIGHT_BRACKET,Input::ButtonBehavior::whenDown,Input::AxisBehavior::positive); // "+" on german keyboard
    Input::mapKeyToInput("CameraMovementSpeed",GLFW_KEY_SLASH,Input::ButtonBehavior::whenDown,Input::AxisBehavior::negative); // "-" on german keyboard
    Input::mapKeyToInput("CameraToggleMode",GLFW_KEY_R);
    Input::mapKeyToInput("CameraSlowMode",GLFW_KEY_LEFT_SHIFT,Input::ButtonBehavior::whenDown);
    Input::mapKeyToInput("CameraFastMode",GLFW_KEY_SPACE,Input::ButtonBehavior::whenDown);

}