const std = @import("std");
const err = @import("err.zig");
const c = @import("c.zig").c;

pub const Shader = struct {
    id: u32,

    /// Compile and link vertex and fragment shaders
    /// @params - The glsl source code for the shaders, in a NULL-terminated string format
    /// @return - Shader object with associated glShaderProgram id
    pub fn create(
        vertex_src: []const u8,
        fragment_src: []const u8,
    ) !Shader {
        const vert_shader: u32 = c.glCreateShader(c.GL_VERTEX_SHADER);
        c.glShaderSource(vert_shader, 1, @ptrCast(&vertex_src), null);
        c.glCompileShader(vert_shader);
        try shaderDidCompile(vert_shader);

        const frag_shader: u32 = c.glCreateShader(c.GL_FRAGMENT_SHADER);
        c.glShaderSource(frag_shader, 1, @ptrCast(&fragment_src), null);
        c.glCompileShader(frag_shader);
        try shaderDidCompile(frag_shader);

        const _id: u32 = c.glCreateProgram();

        c.glAttachShader(_id, vert_shader);
        c.glAttachShader(_id, frag_shader);
        c.glLinkProgram(_id);
        try shadersDidLink(_id);

        c.glDeleteShader(vert_shader);
        c.glDeleteShader(frag_shader);

        return .{ .id = _id };
    }

    pub fn use(self: Shader) void {
        c.glUseProgram(self.id);
    }

    fn shaderDidCompile(shader: u32) err.GL!void {
        var success: c_int = 0;
        var infoLog: [512]u8 = .{' '} ** 512;
        c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);

        if (success == 0) {
            var len: usize = 0;
            c.glGetShaderInfoLog(shader, infoLog.len, @ptrCast(&len), &infoLog);
            std.debug.print("Shader compilation error: {s}\n", .{infoLog[0..len]});
            return err.GL.shader_compilation;
        }
    }

    fn shadersDidLink(program: u32) err.GL!void {
        var success: c_int = 0;
        var infoLog: [512]u8 = .{' '} ** 512;
        c.glGetProgramiv(program, c.GL_LINK_STATUS, &success);

        if (success == 0) {
            var len: usize = 0;
            c.glGetProgramInfoLog(program, 512, @ptrCast(&len), &infoLog);
            std.debug.print("Shader linking error: {s}\n", .{infoLog[0..len]});
            return err.GL.shader_linking;
        }
    }

    pub fn setUniformB(self: *Shader, name: []const u8, value: bool) void {
        c.glUniform1i(c.glGetUniformLocation(self.id, name.ptr), @intFromBool(value));
    }
    pub fn setUniformI(self: *Shader, name: []const u8, value: i32) void {
        c.glUniform1i(c.glGetUniformLocation(self.id, name.ptr), value);
    }
    pub fn setUniformU(self: *Shader, name: []const u8, value: u32) void {
        c.glUniform1ui(c.glGetUniformLocation(self.id, name.ptr), value);
    }
    pub fn setUniformF(self: *Shader, name: []const u8, value: f32) void {
        c.glUniform1f(c.glGetUniformLocation(self.id, name.ptr), value);
    }

};
