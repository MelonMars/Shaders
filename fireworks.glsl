vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);
    return a + b * cos(6.28318 * (c * t + d));
}

vec3 tailPalette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 0.5);
    vec3 d = vec3(0.363, 0.516, 0.657);
    return a + b * cos(6.28318 * (c * t + d));
}

float noise(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = noise(i);
    float b = noise(i + vec2(1.0, 0.0));
    float c = noise(i + vec2(0.0, 1.0));
    float d = noise(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for(int i = 0; i < 5; i++) {
        value += amplitude * smoothNoise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

vec3 drawFirework(vec2 uv, vec2 pos, float time, float seed) {
    float launch = mod(time + seed * 3.0, 4.0);
    float burstTime = launch - 1.5;
    
    vec3 col = vec3(0.0);
    
    if(launch < 1.5) {
        float rocketY = -0.8 + launch * 0.8;
        vec2 rocketPos = vec2(pos.x, rocketY);
        
        for(float seg = 0.0; seg < 1.0; seg += 0.05) {
            float segY = rocketY - seg * 0.4;
            if(segY < -0.8) continue;
            
            float wiggle1 = sin(segY * 8.0 + time * 4.0 + seed * 6.28) * 0.04;
            float wiggle2 = sin(segY * 15.0 - time * 3.0 + seed * 3.14) * 0.02;
            float wiggle3 = cos(segY * 20.0 + time * 5.0) * 0.015;
            
            float flowNoise = fbm(vec2(segY * 5.0 - time * 2.0, pos.x * 10.0 + seed)) * 0.03;
            
            vec2 trailPos = vec2(pos.x + wiggle1 + wiggle2 + wiggle3 + flowNoise, segY);
            vec2 toTrail = uv - trailPos;
            float dist = length(toTrail);
            
            float glow = 0.003 / (dist + 0.001);
            glow += 0.008 / (dist + 0.005);
            
            float segFade = (1.0 - seg) * smoothstep(1.5, 0.0, launch);
            segFade *= smoothstep(0.0, 0.3, launch);
            
            vec3 trailColor = tailPalette(seed + seg * 2.0 - time * 0.3);
            col += trailColor * glow * segFade * 2.0;
        }
        
        vec2 toRocket = uv - rocketPos;
        float rocketDist = length(toRocket);
        float rocketGlow = 0.01 / (rocketDist + 0.002);
        rocketGlow += 0.02 / (rocketDist + 0.01);
        col += tailPalette(seed - time * 0.5) * rocketGlow * smoothstep(1.5, 0.0, launch);
    }
    
    float burstY = -0.8 + 1.5 * 0.8;
    vec2 burstPos = vec2(pos.x, burstY);
    
    if(burstTime > 0.0 && burstTime < 2.5) {
        float fade = 1.0 - burstTime / 2.5;
        fade = pow(fade, 0.7);
        
        int rays = 32;
        for(int i = 0; i < rays; i++) {
            float angle = float(i) * 6.28318 / float(rays);
            angle += seed * 6.28;
            
            float angleWave = sin(time * 2.0 + float(i) * 0.5) * 0.3;
            angle += angleWave;
            
            vec2 dir = vec2(cos(angle), sin(angle));
            
            float flowSpeed = 0.3 + 0.2 * noise(vec2(float(i), seed));
            float flowDist = burstTime * flowSpeed;
            
            float waveAmt = fbm(dir * 3.0 + time * 0.5) * 0.15;
            vec2 flowPos = burstPos + dir * flowDist + vec2(waveAmt, waveAmt * 0.7);
            
            vec2 toParticle = uv - flowPos;
            float dist = length(toParticle);
            
            float particleGlow = 0.003 / (dist + 0.001);
            particleGlow += 0.008 / (dist + 0.005);
            
            float colorT = float(i) / float(rays) + time * 0.1 + seed;
            vec3 rayCol = palette(colorT);
            
            float trailDot = dot(normalize(toParticle), dir);
            if(trailDot > 0.0) {
                float trailGlow = 0.001 / (dist + 0.001) * trailDot;
                particleGlow += trailGlow * 0.5;
            }
            
            col += rayCol * particleGlow * fade;
        }
        
        vec2 toCore = uv - burstPos;
        float coreDist = length(toCore);
        float coreWave = fbm(toCore * 10.0 + time) * 0.02;
        coreDist += coreWave;

        float coreGlow = 0.008 / (coreDist * coreDist + 0.0001);
        coreGlow += 0.05 / (coreDist + 0.01);

        float initialFlash = exp(-burstTime * 4.0);
        coreGlow += initialFlash * 0.3 / (coreDist * coreDist + 0.0001);

        col += palette(seed + time * 0.2) * coreGlow * 2.0;
    }
    
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    vec3 col = vec3(0.0);
    
    col = mix(vec3(0.01, 0.01, 0.03), vec3(0.02, 0.01, 0.04), uv.y * 0.5 + 0.5);
    
    col += drawFirework(uv, vec2(-1.2, 0.4), iTime, 0.0);
    col += drawFirework(uv, vec2(0.8, 0.6), iTime, 1.3);
    col += drawFirework(uv, vec2(0.0, -0.3), iTime, 2.6);
    col += drawFirework(uv, vec2(-1.5, -0.2), iTime, 0.7);
    col += drawFirework(uv, vec2(0.9, -0.5), iTime, 1.9);
    
    float atmosphere = fbm(uv * 2.0 + iTime * 0.1) * 0.05;
    col += atmosphere * palette(iTime * 0.1);
    
    float vig = 1.0 - length(uv * 0.5);
    vig = smoothstep(0.3, 1.0, vig);
    col *= vig;
    
    col = pow(col, vec3(0.9));
    
    fragColor = vec4(col, 1.0);
}
