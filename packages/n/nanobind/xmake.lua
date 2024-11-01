package("nanobind")
    set_homepage("https://github.com/wjakob/nanobind")
    set_description("nanobind: tiny and efficient C++/Python bindings")
    set_license("BSD-3-Clause")

    set_urls("https://github.com/wjakob/nanobind/archive/refs/tags/$(version).tar.gz",
             "https://github.com/wjakob/nanobind.git", {submodules = false})

    add_versions("v2.2.0", "bfbfc7e5759f1669e4ddb48752b1ddc5647d1430e94614d6f8626df1d508e65a")

    add_deps("cmake")
    add_deps("robin-map", "python >=3.8")

    on_install(function (package)
        local builddir = path.join(os.curdir(), "build")

        local configs = {
            "-DNB_TEST=OFF",
            "-DNB_CREATE_INSTALL_RULES=ON",
            "-DNB_USE_SUBMODULE_DEPS=OFF",
            "-DNB_INSTALL_DATADIR=" .. builddir,
        }
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:is_debug() and "Debug" or "Release"))
        import("package.tools.cmake").install(package, configs)

        os.cp(path.join(package:scriptdir(), "port", "xmake.lua"), path.join(builddir, "xmake.lua"))
        import("package.tools.xmake").install(package, {"--project=" .. builddir})

        if package:config("shared") then
            package:add("defines", "NB_SHARED")

            if package:is_plat("macosx") then
                local response = package:installdir("cmake/darwin-ld-cpython.sym")
                package:add("shflags", "-Wl,-dead_strip", "-Wl,x", "-Wl,-S", "-Wl,@" .. response)
            elseif not package:is_plat("windows") then
                package:add("shflags", "-Wl,-s")
            end
        else
            if not package:is_plat("windows", "macosx") then
                package:add("cxflags", "-ffunction-sections", "-fdata-sections")
                package:add("ldflags", "-Wl,--gc-sections")
            end
        end
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            int add(int a, int b) { return a + b; }
            NB_MODULE(my_ext, m) {
                m.def("add", &add);
            }
            void test() {}
        ]]}, {configs = {languages = "c++17"}, includes = "nanobind/nanobind.h"}))
    end)
