#version 320 es

precision mediump float;

// Hyprland full-screen shader for a subtle “digital vibrance” effect.
// Increases saturation slightly while nudging value for deeper blacks.

layout(location = 0) out vec4 fragColor;
in vec2 v_texcoord;

uniform sampler2D tex;

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(
        abs(q.z + (q.w - q.y) / (6.0 * d + e)),
        d / (q.x + e),
        q.x
    );
}

vec3 hsv2rgb(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    rgb = rgb * rgb * (3.0 - 2.0 * rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

void main() {
    vec4 color = texture(tex, v_texcoord);

    vec3 hsv = rgb2hsv(color.rgb);
    hsv.y = clamp(hsv.y * 1.22, 0.0, 1.0); // bump saturation ~22%
    hsv.z = clamp(hsv.z * 0.98 + 0.02, 0.0, 1.0); // protect highlights, deepen lows

    fragColor = vec4(hsv2rgb(hsv), color.a);
}
