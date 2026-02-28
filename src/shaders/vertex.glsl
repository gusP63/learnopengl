#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;
uniform float offsetX;

out vec4 vColor;
out vec3 vPos;
void main()
{
    vColor = vec4(aColor, 1.0);
    vPos = aPos;
    gl_Position = vec4(aPos.x + offsetX, aPos.y, aPos.z, 1.0);
}
