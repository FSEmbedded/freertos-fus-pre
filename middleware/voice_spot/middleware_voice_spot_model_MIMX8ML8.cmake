include_guard()
message("middleware_voice_spot_model component is included.")


target_include_directories(${MCUX_SDK_PROJECT_NAME} PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}/models/NXP/version_1
)

