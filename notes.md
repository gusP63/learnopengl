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
