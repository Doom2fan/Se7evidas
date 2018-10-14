# ZForms

ZForms is intended as an easy-to-use simple GUI framework for GZDoom's ZScript language for making menus easier for modders who want to create a simple menu without the development overhead of the built in menu system.

## Getting started

ZForms is heavily under construction, so examples and documentation will not be provided until the framework is more fleshed out.

However, if you want to have a play around with it in its early form, follow these instructions:

### Prerequisites

You will need Python 3.6 to run the Build Script necessary to get ZForms working.

### Generating the library

- Use Python 3 to open BuildScript.py.

- You will be prompted to enter a prefix, which will be used in front of all classes in the library. You are encouraged to keep this short - for example, a mod named My Cool Mod might have a prefix of MCM. Once you have chosen a prefix, type it in.

- You will be prompted to choose whether you would like the class names to contain underscores. This is a stylistic choice, and will not affect how the library works beyond class names.

- You will be prompted to enter a folder name. This can be longer than the prefix, and will be where the library files are written to.

- Once this is done, go inside the folder Generated/&lt;YOUR FOLDER NAME HERE&gt;/ and copy the folder called &lt;PREFIX&gt;_ZForms (or &lt;PREFIX&gt;ZForms, depending on underscore choice) into the root of your mod's archive. ZForms should now be ready for your use.

### Using the library

To include the entire library in your mod, you can easily just add `#include "<PREFIX>(_)ZForms/Include.zsc"` in a ZScript file.
If you only need certain files from the library, you can also use `#include` to add these normally.

## License
This project is licensed under the MIT license - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments
- phantombeta as co-creator for the project.

- Nash on the ZDoom Forums for inspiring me to start this on the ZDoom Discord.
- Nash, The Zombie Killer and phantombeta on ZDoom Forums for pitching in implementation ideas on the ZDoom Discord.
