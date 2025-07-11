import { UserConfig } from "vite";
import dts from "vite-plugin-dts";

export const createCommonViteConfigForEntry = (entry: string, ...otherExternals: (RegExp | string)[]): UserConfig =>
  ({
    plugins: [
      dts({
        insertTypesEntry: true,
        rollupTypes: true,
        outDir: "dist",
        // bundledPackages: ["@hiveio/component-internal"],
      }),
    ],
    build: {
      lib: {
        entry,
        formats: ["es" as const],
        fileName: "index",
      },
      outDir: "dist",
      cssMinify: "esbuild" as const,
      minify: "esbuild" as const,
      sourcemap: true,
      emptyOutDir: true,
      rollupOptions: {
        external: ["lit", "@hiveio/component-internal", ...otherExternals],
      },
    },
  }) as UserConfig;

export const commonViteConfig: UserConfig = createCommonViteConfigForEntry("src/index.ts");
