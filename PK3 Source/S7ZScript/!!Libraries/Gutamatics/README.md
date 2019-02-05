# Gutamatics

A Maths library for GZDoom's ZScript language.

## Getting Started

These instructions will show you how to get Gutamatics ready for your own use.

### Prerequisites

You will need Python 3 to run the Build Script necessary to get Gutamatics working.

### Generating the library

- Use Python 3 to open BuildScript.py.

- You will be prompted to enter a prefix, which will be used in front of all classes in the library. You are encouraged to keep this short - for example, a mod named My Cool Mod might have a prefix of MCM. Once you have chosen a prefix, type it in.

- You will be prompted to enter a folder name. This can be longer than the prefix, and will be where the library files are written to.

- Once this is done, go inside the folder Generated/&lt;YOUR FOLDER NAME HERE&gt;/ and copy the folder called &lt;PREFIX&gt;_Gutamatics into the root of your mod's archive. Gutamatics should now be ready for your use.

### Using the library

To include the entire library in your mod, you can easily just add `#include "<PREFIX>_Gutamatics/Include.zsc"` in a ZScript file.
If you only need certain files from the library, you can also use `#include` to add these normally.

## Examples

Examples will be coming soon. Stay tuned!

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
