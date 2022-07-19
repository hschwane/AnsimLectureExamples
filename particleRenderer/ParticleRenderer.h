/*
 * AnsimLectureExample
 * ParticleRenderer.h
 *
 * @author: Hendrik Schwanekamp
 * @mail:   hendrik.schwanekamp@gmx.net
 *
 * Implements the ParticleRenderer class
 *
 * Copyright (c) 2022 Hendrik Schwanekamp
 *
 */

#ifndef ANSIMLECTUREEXAMPLE_PARTICLERENDERER_H
#define ANSIMLECTUREEXAMPLE_PARTICLERENDERER_H

// includes
//--------------------
#include "mpUtils/mpUtils.h"
#include "mpUtils/mpGraphics.h"
//--------------------

// namespace
//--------------------

//--------------------

//-------------------------------------------------------------------
/**
 * class ParticleRenderer
 *
 * usage:
 *
 */
class ParticleRenderer
{
public:
    ParticleRenderer();
    void render();
    void showGui();
    void updateProjection(int width, int height);

    template <class T, bool W, bool M>
    void setBuffers(mpu::gph::Buffer<T,W,M>& position, mpu::gph::Buffer<T,W,M>& velocity);

    //!< different coloring modes
    enum class ColorMode
    {
        CONSTANT = 0,
        VELOCITY = 1,
        SPEED = 2,
    };
    static const int numColorModes=3;

private:
    static const std::string colorModeToString[];

    static constexpr char FRAG_SHADER_PATH[] = PROJECT_SHADER_PATH"particleRenderer.frag";
    static constexpr char VERT_SHADER_PATH[] = PROJECT_SHADER_PATH"particleRenderer.vert";
    static constexpr char GEOM_SHADER_PATH[] = PROJECT_SHADER_PATH"particleRenderer.geom";

    mpu::gph::ShaderProgram m_particleShader;
    mpu::gph::VertexArray m_vao; // dummy vao
    mpu::gph::Camera m_camera;
    glm::mat4 m_projection;

    int m_particleCount{0};

    float m_particleRadius = 0.015f;
    bool m_additiveBlending = false;
    ColorMode m_colorMode = ColorMode::CONSTANT;
    float m_upperBound = 1;   // upper bound of density / velocity transfer function
    float m_lowerBound = 0.001;   // lower bound of density / velocity transfer function
    glm::vec3 m_particleColor     = {1.0, 1.0, 1.0}; // color used when color mode is set to constant
    float m_brightness = 1.0f; // additional brightness for the particles, gets multiplied with color
    float m_particleAlpha = 1.0f;
    float m_materialShininess = 4.0f;
    bool m_linkLightToCamera = true;
    glm::vec3 m_lightPosition = {500, 500, 1000};
    glm::vec3 m_lightDiffuse = {0.4, 0.4, 0.4};
    glm::vec3 m_lightSpecular = {0.3, 0.3, 0.3};
    glm::vec3 m_lightAmbient = {0.1, 0.1, 0.1};
    bool m_renderFlatDisks = false;
    bool m_flatFalloff = false;
    bool m_enableEdgeHighlights = false;
    float m_fieldOfFiew = 45.0f; // field of view in degrees
    float m_near = 0.001f;
    float m_far = 100;

    void setBlending(bool additive);
    void addKeybindings();
};

template <class T, bool W, bool M>
void ParticleRenderer::setBuffers(mpu::gph::Buffer<T, W, M>& position, mpu::gph::Buffer<T, W, M>& velocity)
{
    m_vao.bind();
    m_vao.addAttributeBufferArray(0,0,position,0, sizeof(glm::vec4),4);
    m_vao.addAttributeBufferArray(1,1,velocity,0, sizeof(glm::vec4),4);
    m_particleCount = position.size();
}


#endif //ANSIMLECTUREEXAMPLE_PARTICLERENDERER_H
