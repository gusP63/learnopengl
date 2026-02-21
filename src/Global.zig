const print = @import("std").debug.print;
const c = @import("c.zig").c;
const err = @import("err.zig");

pub const width = 800;
pub const height = 800;

pub var window: *c.SDL_Window = undefined;
pub var glContext: *c.SDL_GLContextState = undefined;

pub fn shaderDidCompile(shader: u32) err.GL!void {
    var success: c_int = 0;
    var infoLog: [512]u8 = .{' '} ** 512;
    c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);

    if (success == 0) {
        var len: usize = 0;
        c.glGetShaderInfoLog(shader, infoLog.len, @ptrCast(&len), &infoLog);
        print("Shader compilation error: {s}\n", .{infoLog[0..len]});
        return err.GL.shader_compilation;
    }
}

pub fn shadersDidLink(program: u32) err.GL!void {
    var success: c_int = 0;
    var infoLog: [512]u8 = .{' '} ** 512;
    c.glGetProgramiv(program, c.GL_LINK_STATUS, &success);

    if (success == 0) {
        var len: usize = 0;
        c.glGetProgramInfoLog(program, 512, @ptrCast(&len), &infoLog);
        print("Shader linking error: {s}\n", .{infoLog[0..len]});
        return err.GL.shader_linking;
    }
}
