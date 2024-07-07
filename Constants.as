//--------------------------------------------------------------------------------
const vec4 s_Transparent = vec4(0, 0, 0, 0);
const vec4 s_Black = vec4(0, 0, 0, 1);
const vec4 s_White = vec4(1, 1, 1, 1);
const vec4 s_Red = vec4(1, 0, 0, 1);
const vec4 s_Green = vec4(0, 1, 0, 1);
const vec4 s_Blue = vec4(0, 0, 1, 1);

//--------------------------------------------------------------------------------
const int s_PointWindowFlags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoResize | UI::WindowFlags::NoMove
                            | UI::WindowFlags::NoCollapse | UI::WindowFlags::NoSavedSettings | UI::WindowFlags::NoScrollbar;

//--------------------------------------------------------------------------------
const float s_PI_4 = Math::PI * 0.25;
const float s_PI_2 = Math::PI * 0.5;
const float s_3PI_4 = Math::PI * 0.75;
const float s_2PI = Math::PI * 2;

//--------------------------------------------------------------------------------
const vec3 s_ItemSpecPosDelta = vec3(0, 56, 0);
