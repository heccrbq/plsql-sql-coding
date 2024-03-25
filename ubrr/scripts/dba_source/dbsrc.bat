IF NOT EXIST "PACKAGE_BODY" (
    mkdir "PACKAGE_BODY"
)
IF NOT EXIST "PACKAGE_SPEC" (
    mkdir "PACKAGE_SPEC"
)
Z:\SQL\sql.bat xxi/xxi1@RUODB @Z:\SQL\dbsrc_package.sql UBRR_XXI5 UBRR_UFM_SKO115FZ_V1_2
