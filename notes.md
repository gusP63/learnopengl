# OpenGL

--- 15/02/2026 ---

## Introduction and design philosophy

opengl 3.3 (modern opengl)
old opengl (pre-3.3) was easier to use and more abstracted, but less performant and less flexible
3.3 onwards adds more features without changing the core of the api

graphics cards manufacturarers can provide extensions to opengl, so we can use modern features even if open gl version does not support it

```c
if(GL_ARB_extension_name)
{
    // Do cool new and modern stuff supported by hardware
}
else
{
    // Extension not supported: do it the old way
}
```

- State Machine
What is referred to as the "OpenGL Context" - the current drawing options.
OpenGL is basically a big state machine, a collection of variables that tell the gpu how it should operate.
For example, if we want to draw lines, we set some options to tell it to draw lines.
The next commands we run will then draw lines.
Later, we may want to draw triangles so we "switch state" to "triangle drawing mode", by changing the options.
The next commands we run will then draw triangles.

- Objects
OpenGL objects - A collection of options, which represent a subset of the OpenGL state.
We may understand them as c-like structs

struct obj_name {
    int opt1;
    int opt2;
    char[] name;
    ...
}

To create an object, we tell opengl to create it and assign a uid as a reference to it.
When we want to operate on an object, we change the opengl state to said object, by binding it to the current context.

```c
// create object
unsigned int objectId = 0;
glGenObject(1, &objectId);

// bind/assign object to context
glBindObject(GL_WINDOW_TARGET, objectId);

// set options of object currently bound to GL_WINDOW_TARGET
glSetObjectOption(GL_WINDOW_TARGET, GL_OPTION_WINDOW_WIDTH, 800);
glSetObjectOption(GL_WINDOW_TARGET, GL_OPTION_WINDOW_HEIGHT, 600);

// set context target back to default
glBindObject(GL_WINDOW_TARGET, 0);
```

This workflow allows us to have multiple objects, referencing various things, say a house model, a character, a tree, etc..
So, for example when we first create the "house" object we set the options to draw the house and bind the model data to it.
Then, when we want to draw the house, we simply "bind it" to the current context and draw it, without having to set all the options again.


## Creating a window

First thing we need to do is create an application window and define an opengl context.
Since these are OS-specific, we will just use a library to handle that (SDL, GLFW, SFML, ...).
In my case, I will be using SLD3.

The way openGL works, it does not give us the functions to use directly, the functions must be "found" and gotten at runtime by the developer, like so:

```c
// define the function’s prototype
typedef void (*GL_GENBUFFERS) (GLsizei, GLuint*);
// find the function and assign it to a function pointer
GL_GENBUFFERS glGenBuffers =
(GL_GENBUFFERS)wglGetProcAddress("glGenBuffers");
// function can now be called as normal
unsigned int buffer;
glGenBuffers(1, &buffer);
```

Since it would be a pain in the ass to do this for every function, we will use GLAD, an open source library that handles this automatically.

```c
#include <glad/glad.h>

// ... init sdl and create gl context

gladLoadGL();

// ... call gl functions

```

--- 19/02/2026 ---

## The Rendering Pipeline

Everything in OpenGL is in 3D space
The rendering pipeline can be divided into two great sections:
- 3d -> 2d
- 2d -> pixels

Each stage requires a lot of parallel computations, which are run on dedicated gpu cores (processing cores), of which there are thousands
The programs that run on these cores are called *Shaders*, written in GLSL (OpenGL Shading Language)

We pass in a list of 3D Coordinates which may make up a triangle, a line, some points... Let's call the array Vertex Data
Vertex Data is an array of Vertices.
A Vertex is a collection of data per 3D Coordinate
This data is represented using *Vertex Attributes* and can be anything we like (position, color, ...)

To tell OpenGL how to draw the points in the Vertex data, we need to hint that to OpenGL when calling the drawing commands, using *Primitives*

Some hints (primitives):
- GL_POINTS
- GL_TRIANGLES
- GL_LINE_STRIP

OpenGL Fragments -> Data required to render a single pixel

Stages of the Rendering Pipeline (Output from one stage -> Input of next stage):
1. Vertex Shader (takes in a single vertex, transforms 3d data -> different 3d data)
2. Primitive Assembly (takes in the vertices from the vertex shader and assembles the points in the primitive given (triangle, line, ...))
3. Geometry Shader (takes in the output from the Primitive Assembly and can generate new shapes from the previous shapes (e.g. subdividing triangles))
4. Rasterization (maps the resulting primitives to pixels on the screen, performs clipping and generates fragments for the next stage)
5. Fragment Shader (calculates the final color of a pixel, this is where the fancy effects occur (lighthing, shadows, ...))
6. Alpha Test and Blending

In modern OpenGL, we must define at least the Vertex Shader and the Fragment Shader ourselves.
Optionally, we may also define the Geometry Shader.

## Hello Triangle

To draw something, we need to give OpenGL some input

1. Vertex Input
3D Coordinates (x, y, z), range [-1.0, 1.0] (Normalized device coordinates, represent what is visible on the screen)

Note: In Normalized Device Coordinates (NDC) (0,0,0 is at the center of the viewport, as opposed to the top-left)

```c
float vertices[] = {
   -0.5, -0.5, 0.0,
    0.5, -0.5, 0.0,
    0.0,  0.5, 0.0,
}
```

Since we're drawing a 2d triangle, we set the z on every point to 0.0 (all same depth)
These coordinates will be transformed to screen-space coordinates via the data provided in glViewport earlier.
The resulting screen-space coordinates will then be transformed to fragments as inputs to our fragment shader.

To send and store data on the GPU, we need to create *Vertex Buffer Objects* (VBO) that can store a large number of vertices

```c
// create the object and assign a UID
unsigned int VBO;
glGenBuffers(1, &VBO);

// bind it to the buffer array
glBindBuffer(GL_ARRAY_BUFFER, VBO);

// any calls from now on will configure the currently bound buffer (VBO)
// copy the data into the buffer's memory
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
```

Draw parameter:
- GL_STREAM_DRAW: the data is set only once and used by the GPU at most a few times.
- GL_STATIC_DRAW: the data is set only once and used many times.
- GL_DYNAMIC_DRAW: the data is changed a lot and used many times.

Once we have the vertex and fragment shaders we need to link them to a 
*shader program* (Combines multiple shaders)
then activate this program when issuing rendering calls

We use vertex array objects (VAO) for storing attributes and configurations to later draw something using said attributes

```c
//.. Process for drawing an object ..
glUseProgram(shader_program);
glBindVertexArray(vao);
// DrawCoolShit()
```
