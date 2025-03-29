shader_type canvas_item;

uniform float emboss_height : hint_range(0,100) = 0.1;
uniform float bump_height : hint_range(0,100) = 0.3;
uniform int blur : hint_range(0,10) = 5;
uniform int bump : hint_range(0,100) = 60;

uniform bool invertX = false;
uniform bool invertY = false;
uniform bool with_distance = true;
uniform bool with_emboss = true;

uniform sampler2D distanceTex;

float gray_scale(sampler2D texture, vec2 texCoord) {
    vec3 color = texture(texture, texCoord).rgb;
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
    vec2 offset = TEXTURE_PIXEL_SIZE;
    float x0 = 0.0, x1 = 0.0, y0 = 0.0, y1 = 0.0;
    float distx0 = 0.0, distx1 = 0.0, disty0 = 0.0, disty1 = 0.0;
    float blur_den = 0.0;
    
    float invX = (-2.0 * float(invertX) + 1.0);
    float invY = (-2.0 * float(invertY) + 1.0);
    
    if (blur > 0) {
        float sigma = float(blur) / 3.0;
        float twoSigmaSq = 2.0 * sigma * sigma;
        
        for(int i = -blur; i <= blur; i++) {
            for(int j = -blur; j <= blur; j++) {
                float distanceSq = float(i*i + j*j);
                float coef = exp(-distanceSq / twoSigmaSq) / (PI * twoSigmaSq);
                blur_den += coef;
                
                vec2 sampleOffset = vec2(float(i), float(j)) * offset;
                
                if(with_emboss) {
                    x0 += gray_scale(TEXTURE, UV - vec2(offset.x, 0.0) + sampleOffset) * coef;
                    x1 += gray_scale(TEXTURE, UV + vec2(offset.x, 0.0) + sampleOffset) * coef;
                    y0 += gray_scale(TEXTURE, UV - vec2(0.0, offset.y) + sampleOffset) * coef;
                    y1 += gray_scale(TEXTURE, UV + vec2(0.0, offset.y) + sampleOffset) * coef;
                }
                if(with_distance) {
                    distx0 += texture(distanceTex, UV + vec2(-offset.x, 0.0) + sampleOffset).r * coef;
                    distx1 += texture(distanceTex, UV + vec2(offset.x, 0.0) + sampleOffset).r * coef;
                    disty0 += texture(distanceTex, UV + vec2(0.0, -offset.y) + sampleOffset).r * coef;
                    disty1 += texture(distanceTex, UV + vec2(0.0, offset.y) + sampleOffset).r * coef;
                }
            }
        }
    } else {
        blur_den = 1.0;
        if(with_emboss) {
            x0 = gray_scale(TEXTURE, UV - vec2(offset.x, 0.0));
            x1 = gray_scale(TEXTURE, UV + vec2(offset.x, 0.0));
            y0 = gray_scale(TEXTURE, UV - vec2(0.0, offset.y));
            y1 = gray_scale(TEXTURE, UV + vec2(0.0, offset.y));
        }
        if(with_distance) {
            distx0 = texture(distanceTex, UV + vec2(-offset.x, 0.0)).r;
            distx1 = texture(distanceTex, UV + vec2(offset.x, 0.0)).r;
            disty0 = texture(distanceTex, UV + vec2(0.0, -offset.y)).r;
            disty1 = texture(distanceTex, UV + vec2(0.0, offset.y)).r;
        }
    }
    
    if (blur_den > 0.0) {
        x0 /= blur_den; x1 /= blur_den; y0 /= blur_den; y1 /= blur_den;
        distx0 /= blur_den; distx1 /= blur_den; disty0 /= blur_den; disty1 /= blur_den;
    }
    
    float bump_factor = 255.0 / float(max(bump, 1));
    distx0 = min(distx0 * bump_factor, 1.0);
    distx1 = min(distx1 * bump_factor, 1.0);
    disty0 = min(disty0 * bump_factor, 1.0);
    disty1 = min(disty1 * bump_factor, 1.0);
    
    distx0 = 1.0 - abs(distx0 - 1.0);
    distx1 = 1.0 - abs(distx1 - 1.0);
    disty0 = 1.0 - abs(disty0 - 1.0);
    disty1 = 1.0 - abs(disty1 - 1.0);
    
    float dx = invX * (-x0 + x1) * 0.5 / offset.x;
    float dy = invY * (-y0 + y1) * 0.5 / offset.y;
    
    float bx = invX * (-distx0 + distx1) * 0.5 / offset.x;
    float by = invY * (-disty0 + disty1) * 0.5 / offset.y;
    
    vec3 normal_emboss = normalize(vec3(dx * emboss_height, dy * emboss_height, 1.0));
    vec3 normal_bump = normalize(vec3(bx * bump_height, by * bump_height, 1.0));
    
    vec3 normal = normalize(normal_emboss + normal_bump);
    normal = normal * 0.5 + 0.5;
    
    vec4 tex = texture(TEXTURE, UV);
    COLOR = vec4(normal, tex.a);
}