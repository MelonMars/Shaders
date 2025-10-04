vec3 palette( float t ) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263,0.416,0.557);
    return a + b*cos( 6.28318*(c*t+d) );
}

float noise(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float a = noise(i);
    float b = noise(i + vec2(1.0, 0.0));
    float c = noise(i + vec2(0.0, 1.0));
    float d = noise(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
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

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    
    float time = iTime * 0.5;
    
    float expansionTime = iTime * 0.1;
    float baseRadius = 0.3 + expansionTime;
    
    vec2 mouse = iMouse.xy / iResolution.xy;
    mouse = (mouse * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);
    
    vec2 mouseVelocity = vec2(0.0);
    if (iMouse.z > 0.0) {
        mouseVelocity.x = sin(iTime * 15.0) * 0.02;
        mouseVelocity.y = cos(iTime * 15.0) * 0.02;
    }
    
    vec2 liquidDisplacement = vec2(0.0);
    float mouseInfluence = 0.0;
    
    if (iMouse.z > 0.0) {
        float mouseDist = length(p - mouse);
        float influence = exp(-mouseDist * 2.0) * smoothstep(0.5, 0.0, mouseDist);
        
        liquidDisplacement = mouseVelocity * influence * 3.0;
        mouseInfluence = influence;
    }
    
    vec2 displacedP = p - liquidDisplacement;
    
    vec2 flow1 = vec2(
        fbm(displacedP * 2.0 + vec2(time * 0.2, time * 0.1)) + liquidDisplacement.x * 2.0,
        fbm(displacedP * 2.0 + vec2(time * 0.15, -time * 0.25)) + liquidDisplacement.y * 2.0
    );
    
    vec2 flow2 = vec2(
        fbm(displacedP * 3.0 + flow1 * 0.5 + vec2(-time * 0.1, time * 0.2)),
        fbm(displacedP * 3.0 + flow1 * 0.5 + vec2(time * 0.3, time * 0.1))
    );
    
    if (iMouse.z > 0.0) {
        float mouseDist = length(displacedP - mouse);
        vec2 perpendicular = vec2(-mouseVelocity.y, mouseVelocity.x);
        float swirl = exp(-mouseDist * 3.0) * 0.5;
        flow1 += perpendicular * swirl;
        flow2 += perpendicular * swirl * 0.5;
    }
    
    vec2 distorted = displacedP + flow1 * 0.3 + flow2 * 0.2;
    
    float thickness = 0.0;
    thickness += fbm(distorted * 4.0 + time * vec2(0.1, -0.2)) * 0.5;
    thickness += fbm(distorted * 8.0 - time * vec2(0.2, 0.1)) * 0.25;
    thickness += fbm(distorted * 16.0 + time * vec2(-0.1, 0.3)) * 0.125;
    
    float dist = length(displacedP);
    
    float edgeNoise = fbm(displacedP * 8.0 + time * vec2(0.05, -0.03)) * 0.15;
    float organicRadius = baseRadius + edgeNoise;
    float radialMask = smoothstep(organicRadius + 0.2, organicRadius - 0.1, dist);
    
    if (iMouse.z > 0.0) {
        float mouseDist = length(displacedP - mouse);
        float pushEffect = exp(-mouseDist * 1.5) * mouseInfluence;
        radialMask += pushEffect * 0.3;
    }
    
    thickness *= radialMask;
    
    vec2 viewDir = normalize(displacedP);
    float angle = atan(viewDir.y, viewDir.x);
    float interference = sin(thickness * 20.0 + angle * 3.0 + time) * 0.5 + 0.5;
    
    float colorParam = thickness * 3.0 + interference * 0.3 + sin(time * 0.5) * 0.1;
    if (iMouse.z > 0.0) {
        colorParam += mouseInfluence * 0.5;
    }
    
    vec3 color = palette(colorParam);
    
    float shimmer = pow(max(0.0, sin(thickness * 30.0 + time * 2.0)), 8.0);
    color += vec3(shimmer * 0.3);
    
    float alpha = smoothstep(0.0, 0.2, thickness) * radialMask;
    
    if (iMouse.z > 0.0) {
        alpha += mouseInfluence * 0.2;
    }
    
    alpha = clamp(alpha, 0.0, 1.0);
    color *= alpha;
    
    vec3 background = vec3(0.1, 0.12, 0.15);
    
    if (iMouse.z > 0.0 && alpha < 0.3) {
        float mouseDist = length(p - mouse);
        float bgRipple = sin(mouseDist * 10.0 - iTime * 5.0) * 0.5 + 0.5;
        float bgInfluence = exp(-mouseDist * 2.0) * bgRipple * 0.1;
        vec3 rippleColor = palette(bgInfluence * 2.0);
        background = mix(background, rippleColor, bgInfluence);
    }
    
    color = mix(background, color, alpha);
    
    color = pow(color, vec3(0.9));
    color = mix(vec3(dot(color, vec3(0.299, 0.587, 0.114))), color, 1.3);
    
    fragColor = vec4(color, 1.0);
}
