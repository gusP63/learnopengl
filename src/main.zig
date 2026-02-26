const print = @import("std").debug.print;
const Global = @import("Global.zig");
const err = @import("err.zig");
const c = @import("c.zig").c;
const Shader = @import("shader.zig").Shader;

var quit: bool = false;

//var shader_program: u32 = undefined;

var vao: u32 = undefined; // vertex array object
var vbo: u32 = undefined; // vertex buffer object

var vao_rect: u32 = undefined;
var vbo_rect: u32 = undefined;
var ebo: u32 = undefined; // element buffer object

var my_vertex_color_location: i32 = undefined;
var shader_obj: Shader = undefined;

const State = struct {
    const Shape = enum { draw_triangle, draw_rect };
    const DrawMode = enum { fill, wireframe };

    shape: Shape = .draw_triangle,
    draw_mode: DrawMode = .fill,
};

var state: State = .{};

const vertex_shader_source =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec3 aColor;
    \\
    \\out vec4 vColor;
    \\void main()
    \\{
    \\ gl_Position = vec4(aPos, 1.0);
    \\ vColor = vec4(aColor, 1.0);
    \\}
;
//
const fragment_shader_source =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\in vec4 vColor;
    \\
    \\uniform vec4 MyColor;
    \\void main()
    \\{
    \\//FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\//FragColor = MyColor;
    \\ FragColor = vColor;
    \\}
;
//
fn input() void {
    var event: c.SDL_Event = undefined;

    while (c.SDL_PollEvent(&event)) {
        switch (event.type) {
            c.SDL_EVENT_QUIT => quit = true,
            c.SDL_EVENT_WINDOW_RESIZED => {
                var w: c_int = 0;
                var h: c_int = 0;
                _ = c.SDL_GetWindowSize(Global.window, &w, &h);

                if (w != 0 and h != 0)
                    c.glViewport(0, 0, w, h);
            },
            c.SDL_EVENT_KEY_UP => {
                switch (event.key.key) {
                    c.SDLK_ESCAPE => quit = true,
                    // c.SDLK_1 => c.glClearColor(0, 0, 0, 1),
                    // c.SDLK_2 => c.glClearColor(1, 1, 1, 1),
                    c.SDLK_R => state.shape = .draw_rect,
                    c.SDLK_T => state.shape = .draw_triangle,
                    c.SDLK_SPACE => {
                        // cycle through wireframe/fill
                        //state.draw_mode = @enumFromInt((@intFromEnum(state.draw_mode) + 1) % (@typeInfo(State.DrawMode).@"enum".fields.len));
                        state.draw_mode = switch (state.draw_mode) {
                            .wireframe => .fill,
                            .fill => .wireframe,
                        };

                        switch (state.draw_mode) {
                            .fill => c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_FILL),
                            .wireframe => c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE),
                        }
                    },
                    else => {},
                }
            },
            else => {},
        }
    }
}

var greenValue: f32 = 0;
var prev: u64 = 0;
var offset: f32 = 0.01;

fn draw() void {
    c.glClearColor(0, 0.5, 0.5, 1);
    c.glClear(c.GL_COLOR_BUFFER_BIT);

    // const now = c.SDL_GetTicks();
    // const elapsed = c.SDL_GetTicks() - prev;
    // if (elapsed > 20) {
    //     prev = now;
    //
    //     if (greenValue >= 1) offset = -0.01;
    //     if (greenValue <= 0.5) offset = 0.01;
    //
    //     greenValue += offset;
    //     c.glUniform4f(my_vertex_color_location, 0.0, greenValue, 0.0, 1.0);
    // }

    shader_obj.use();
    switch (state.shape) {
        .draw_rect => {
            c.glBindVertexArray(vao_rect);
            c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, @ptrFromInt(0));
        },
        .draw_triangle => {
            c.glBindVertexArray(vao);
            c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        },
    }
    c.glBindVertexArray(0);

    _ = c.SDL_GL_SwapWindow(Global.window);
}

pub fn main() !void {
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) return err.SDL.init;
    defer c.SDL_Quit();
    errdefer print("{s}", .{c.SDL_GetError()});

    _ = c.SDL_GL_SetAttribute(c.SDL_GL_DOUBLEBUFFER, 1);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);
    _ = c.SDL_GL_SetSwapInterval(1);

    Global.window = c.SDL_CreateWindow(
        "OpenGL Window",
        Global.width,
        Global.height,
        c.SDL_WINDOW_OPENGL,
    ) orelse return err.SDL.init;
    defer c.SDL_DestroyWindow(Global.window);

    const glContext = c.SDL_GL_CreateContext(Global.window) orelse return err.SDL.init;
    defer _ = c.SDL_GL_DestroyContext(glContext);

    const version = c.gladLoadGLLoader(@ptrCast(&c.SDL_GL_GetProcAddress));
    if (version == 0) return err.SDL.init;

    // initialization code
    c.glViewport(0, 0, Global.width, Global.height);

    shader_obj = try Shader.create(
        "src/shaders/vertex.glsl",
        "src/shaders/fragment.glsl",
    );

    my_vertex_color_location = c.glGetUniformLocation(shader_obj.id, "MyColor");

    // - init triangle
    // create a vao and bind it to a vbo and attribute pointer
    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);

    // const triangle_vertices = [_]f32{
    //     -0.5, -0.5, 0,
    //     0.5,  -0.5, 0,
    //     0.0,  0.5,  0,
    // };
    //
    const triangle_vertices_with_colors = [_]f32{
        -0.5, -0.5, 0, 1.0, 0.0, 0.0,
        0.5,  -0.5, 0, 0.0, 1.0, 0.0,
        0.0,  0.5,  0, 0.0, 0.0, 1.0,
    };

    c.glBindVertexArray(vao);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, triangle_vertices_with_colors.len * @sizeOf(f32), &triangle_vertices_with_colors, c.GL_STATIC_DRAW);

    // tell openGL how to interpret the data from vertex buffer
    c.glVertexAttribPointer(
        0, // index of vertex attribute (see vertex_shader_source, must align with what we have there)
        3, // size (1,2,3,4) vec3 in this case
        c.GL_FLOAT, // data type
        c.GL_FALSE, // normalize data?
        6 * @sizeOf(f32), // stride (space between consecutive vertex attributes)
        @ptrFromInt(0), // offset of where the position data begins in the buffer
    );
    c.glEnableVertexAttribArray(0);

    c.glVertexAttribPointer(
        1,
        3,
        c.GL_FLOAT,
        c.GL_FALSE,
        6 * @sizeOf(f32),
        @ptrFromInt(3 * @sizeOf(f32)),
    );
    c.glEnableVertexAttribArray(1);

    // unbind the vbo
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    // unbind the vao (optional)
    c.glBindVertexArray(0);

    // rect init
    const rect_vertices = [_]f32{ // vertex data (stored in vbo)
        -0.5, 0.5, 0, // top left
        0.5, 0.5, 0, // top right
        0.5, -0.5, 0, // bottom right
        -0.5, -0.5, 0, // bottom left
    };

    const rect_indices = [_]u32{ // order in which to draw triangles (stored in ebo)
        0, 1, 2, // first triangle
        0, 2, 3, // second triangle
    };

    c.glGenVertexArrays(1, &vao_rect);
    c.glGenBuffers(1, &vbo_rect);
    c.glGenBuffers(1, &ebo);

    c.glBindVertexArray(vao_rect);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo_rect);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        rect_vertices.len * @sizeOf(f32),
        &rect_vertices,
        c.GL_STATIC_DRAW,
    );

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    c.glBufferData(
        c.GL_ELEMENT_ARRAY_BUFFER,
        rect_indices.len * @sizeOf(u32),
        &rect_indices,
        c.GL_STATIC_DRAW,
    );

    c.glVertexAttribPointer(
        0,
        3,
        c.GL_FLOAT,
        c.GL_FALSE,
        3 * @sizeOf(f32),
        @ptrFromInt(0),
    );
    c.glEnableVertexAttribArray(0);

    while (!quit) {
        input();
        draw();
    }
}
