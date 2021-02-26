using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class CloudShadowFeature : ScriptableRendererFeature
{
    public RenderPassEvent renderPassEvent;

    [Tooltip("叠加颜色")]
    public Color m_Color = Color.white;
    [Tooltip("XY为起始位置，zw为XY移动速度")]
    public Vector4 m_StartXYSpeedXY = new Vector4(5, 5, 0, 0);
    [Tooltip("贴图缩放大小，值越小越大")]
    public float m_Scale = 0.1f;
    [Tooltip("可以移动的大小范围")]
    public float m_WorldSize = 200;
    public Texture2D m_Tex;
    CloudShadowPass m_Pass;
    //feature被创建时调用
    public override void Create()
    {
        var mat = new Material(Shader.Find("Hidden/CloudShadow"));
        mat.SetColor("_Color", m_Color);
        mat.SetTexture("_CloudTex", m_Tex);
        mat.SetVector("_StartXYSpeedXY", m_StartXYSpeedXY);
        mat.SetFloat("_Scale", m_Scale);
        mat.SetFloat("_WorldSize", m_WorldSize);
        m_Pass = new CloudShadowPass(mat, renderPassEvent);
    }
    //每一帧都会被调用
    public override void AddRenderPasses(UnityEngine.Rendering.Universal.ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        //将当前渲染的颜色RT传到Pass中
        m_Pass.Setup(renderer.cameraColorTarget);
        //将这个pass添加到渲染队列
        renderer.EnqueuePass(m_Pass);
    }
}
