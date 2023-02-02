Shader "Unlit/VolumeShader"
{
    Properties
    {
        [MainTexture] _VolumeTexture ("Volume Texture", 3D) = "white" {}
        [MainColor] _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Alpha ("Alpha", float) = 0.02
        _StepSize ("Step Size", float) = 0.025

        [HideInInspector] _CutterPosition ("Cutter Position", Vector) = (0.0, 0.0, 0.0, 1.0)
        [HideInInspector] _CutterNormal ("Cutter Normal", Vector) = (0.0, 0.0, 0.0, 1.0)
        [HideInInspector] _Cutting ("Cutting?", float) = 0.0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent+1" "RenderType" = "Transparent" "ForceNoShadowCasting" = "True" }
        Blend One OneMinusSrcAlpha
        LOD 100

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Maximum amount of raymarching samples
            #define MAX_STEP_COUNT 64

            // Allowed floating point inaccuracy
            #define EPSILON 0.00001f

            TEXTURE3D(_VolumeTexture);
            SAMPLER(linear_clamp_sampler);

            float4 _VolumeTexture_ST;
            float4 _Color;
            float _Alpha;
            float _StepSize;

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _CutterPosition)
                UNITY_DEFINE_INSTANCED_PROP(float4, _CutterNormal)
                UNITY_DEFINE_INSTANCED_PROP(float, _Cutting)
            UNITY_INSTANCING_BUFFER_END(Props)

            struct Attributes
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float3 objectVertex : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes v)
            {
                Varyings o;

                ZERO_INITIALIZE(Varyings, o);

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                // Vertex in object space this will be the starting point of raymarching
                o.objectVertex = v.vertex.xyz;

                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }

            float AddSample(float accumulator, float currentSample)
            {
                accumulator += (1.0 - accumulator) * currentSample;
                return accumulator;
            }

            float CutterPlaneMask(float3 samplePosition, float3 cutterPositionWorld, float3 cutterNormal, float cutting) {
                float visible = dot(cutterNormal, normalize(cutterPositionWorld - TransformObjectToWorld(samplePosition)));
                return max(ceil(clamp(visible, -0.9, 1.0)), 1.0 - cutting);
            }

            float3 JumpRayToCuttingPlane(float3 rayOrigin, float3 rayDirection, float3 cutterPositionWorld, float3 cutterNormal) {
                // TODO

                rayOrigin = TransformObjectToWorld(rayOrigin);

                if (dot(cutterPositionWorld - rayOrigin, cutterNormal) > 0)
                    rayDirection = -rayDirection;
                
                float d = dot(cutterPositionWorld, -cutterNormal);
                float t = -(dot(cutterNormal, rayOrigin) + d) / dot(cutterNormal, rayDirection);
                float3 intersection = rayOrigin + max(t, 0) * rayDirection;

                return TransformWorldToObject(intersection);
            }

            half4 frag(Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                // Start raymarching at the front surface of the object
                float3 rayOrigin = i.objectVertex;

                // Use vector from camera to object surface to get ray direction
                float3 rayDirection = normalize(i.objectVertex - TransformWorldToObject(_WorldSpaceCameraPos));
                // float3 rayDirectionWorld = normalize(TransformObjectToWorld(i.objectVertex) - _WorldSpaceCameraPos);

                float4 cutterPositionWorld = UNITY_ACCESS_INSTANCED_PROP(Props, _CutterPosition);
                float3 cutterNormal = UNITY_ACCESS_INSTANCED_PROP(Props, _CutterNormal).xyz;
                float cutting = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutting);
                
                /*
                if (UNITY_ACCESS_INSTANCED_PROP(Props, _Cutting))
                    rayOrigin = JumpRayToCuttingPlane(rayOrigin, rayDirectionWorld, cutterPositionWorld.xyz, cutterNormal);
                */

                float3 samplePosition = rayOrigin;
                float accumulator = 0;

                // Raymarch through object space
                [unroll]
                for (int i = 0; i < MAX_STEP_COUNT; i++)
                {
                    // Accumulate color only within unit cube bounds
                    if(max(abs(samplePosition.x), max(abs(samplePosition.y), abs(samplePosition.z))) >= 0.5f + EPSILON)
                        continue;

                    float sampledValue = SAMPLE_TEXTURE3D(_VolumeTexture, linear_clamp_sampler, samplePosition + float3(0.5f, 0.5f, 0.5f)).a;
                    sampledValue *= CutterPlaneMask(samplePosition, cutterPositionWorld.xyz, cutterNormal, cutting);
                    sampledValue *= _Alpha;
                    accumulator = AddSample(accumulator, sampledValue);
                    samplePosition += rayDirection * _StepSize;
                }

                return half4(_Color.rgb * accumulator, accumulator);
            }

            ENDHLSL
        }
    }
}
