const
  cTexturedPixelShaderCode: string =
    'precision mediump float;' +
    'uniform sampler2D SourceTex;' +
    'varying vec4 OutpColor;' +
    'varying vec2 OutpTexCoord;' +
    'void main()' +
    '{' +
    '  gl_FragColor = texture2D(SourceTex, OutpTexCoord) * OutpColor;' +
    '}';