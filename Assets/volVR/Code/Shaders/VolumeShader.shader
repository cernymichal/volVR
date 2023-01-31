Shader "Unlit/VolumeShader"
{
    Properties
    {
        _VolumeTexture ("Volume Texture", 3D) = "white" {}
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _CutterPosition ("Cutter Position", Vector) = (0.0, 0.0, 0.0, 0.0)
        _CutterNormal ("Cutter Normal", Vector) = (0.0, 0.0, 0.0, 0.0)
        _Alpha ("Alpha", float) = 0.02
        _StepSize ("Step Size", float) = 0.01
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend One OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            // Maximum amount of raymarching samples
            #define MAX_STEP_COUNT 128

            // Allowed floating point inaccuracy
            #define EPSILON 0.00001f

            sampler3D _VolumeTexture;
            float4 _VolumeTexture_ST;

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 objectVertex : TEXCOORD0;
                float3 vectorToSurface : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            UNITY_DEFINE_INSTANCED_PROP(float4, _CutterPosition)
            UNITY_DEFINE_INSTANCED_PROP(float4, _CutterNormal)
            UNITY_DEFINE_INSTANCED_PROP(float, _Alpha)
            UNITY_DEFINE_INSTANCED_PROP(float, _StepSize)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert(appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                // Vertex in object space this will be the starting point of raymarching
                o.objectVertex = v.vertex;

                // Calculate vector from camera to vertex in world space
                o.vectorToSurface = v.vertex - mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1)).xyz;

                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float4 BlendUnder(float4 color, float4 newColor)
            {
                color.rgb += (1.0 - color.a) * newColor.a * newColor.rgb;
                color.a += (1.0 - color.a) * newColor.a;
                return color;
            }

            float CutterPlaneMask(float4 cutterPositionWorld, float3 cutterNormal, float3 samplePosition) {
                float visible = dot(cutterNormal, normalize(cutterPositionWorld - mul(unity_ObjectToWorld, float4(samplePosition, 1)).xyz));
                return max(ceil(clamp(visible, -0.9, 1.0)), 1.0 - cutterPositionWorld.w);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                // Start raymarching at the front surface of the object
                float3 rayOrigin = i.objectVertex;

                // Use vector from camera to object surface to get ray direction
                float3 rayDirection = normalize(i.vectorToSurface);

                float4 cutterPositionWorld = UNITY_ACCESS_INSTANCED_PROP(Props, _CutterPosition);
                float3 cutterNormal = UNITY_ACCESS_INSTANCED_PROP(Props, _CutterNormal).xyz;

                float4 color = float4(UNITY_ACCESS_INSTANCED_PROP(Props, _Color).rgb, 0);
                float3 samplePosition = rayOrigin;

                float alpha = UNITY_ACCESS_INSTANCED_PROP(Props, _Alpha);
                float stepSize = UNITY_ACCESS_INSTANCED_PROP(Props, _StepSize);

                // Raymarch through object space
                for (int i = 0; i < MAX_STEP_COUNT; i++)
                {
                    // Accumulate color only within unit cube bounds
                    if(max(abs(samplePosition.x), max(abs(samplePosition.y), abs(samplePosition.z))) < 0.5f + EPSILON)
                    {
                        float4 sampledColor = tex3D(_VolumeTexture, samplePosition + float3(0.5f, 0.5f, 0.5f));
                        sampledColor *= CutterPlaneMask(cutterPositionWorld, cutterNormal, samplePosition);
                        sampledColor.a *= alpha;
                        color = BlendUnder(color, sampledColor);
                        samplePosition += rayDirection * stepSize;
                    }
                }

                return float4(color.rgb * color.a, color.a);
            }
            ENDCG
        }
    }
}
