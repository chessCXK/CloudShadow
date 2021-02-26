Shader "Hidden/CloudShadow"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
		_CloudTex("CloudTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
		{
			ZTest Off Cull Off ZWrite Off
			HLSLPROGRAM
			
			#include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#pragma vertex vertex_depth
			#pragma fragment frag_depth

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);

			TEXTURE2D(_CloudTex);
			SAMPLER(sampler_CloudTex);

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			float4x4 _ViewPortRay;
			half4 _Color;
			half4 _StartXYSpeedXY;
			half _Scale;
			half _WorldSize;
			
			struct Attributes
            {
                float4 positionOS : POSITION;
                float4 texcoord : TEXCOORD0;
            };

			struct Varyings
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 rayDir : TEXCOORD1;
			};
	
			Varyings vertex_depth(Attributes v)
			{
				Varyings o = (Varyings)0;
				o.pos = TransformWorldToHClip(v.positionOS);
				o.uv = v.texcoord.xy;

				//用texcoord区分四个角
				int index = 0;
				int x = step(0.5, v.texcoord.x);
				int y = step(0.5, v.texcoord.y);
				index = x + y;
				if (x == 1 && y == 0)
					index = 3;

				o.rayDir = _ViewPortRay[index];
				return o;
			}
	
			half4 frag_depth(Varyings i) : SV_Target
			{
				half4 screenTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

				//重建世界坐标
				half depthTextureValue1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
				half dpLinear = Linear01Depth(depthTextureValue1, _ZBufferParams);
				half3 worldPos = _WorldSpaceCameraPos + dpLinear * i.rayDir.xyz;

				_StartXYSpeedXY = -_StartXYSpeedXY;
				//开始位置
				worldPos.xz = worldPos.xz + _StartXYSpeedXY.xy;

				//移动
				half2 offset = _StartXYSpeedXY.zw *_Time.x;
				offset = offset % _WorldSize;//限制移动大小
				worldPos.xz = worldPos.xz + offset;

				//缩放
				worldPos.xz = worldPos.xz * _Scale;

				//超出0-1边界result等于0
				half result = step(0, worldPos.x);
				result = result * step(worldPos.x, 1);
				result = result * step(0, worldPos.z);
				result = result * step(worldPos.z, 1);

				half4 cloudTex = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, worldPos.xz) * _Color;
	
				//叠加在原有渲染的基础上
				return lerp(screenTex, screenTex * cloudTex, result * cloudTex.a);
			}
			
			ENDHLSL
		}
    }
}
