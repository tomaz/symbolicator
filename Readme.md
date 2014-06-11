Symbolicator
------------

Symbolicator is command line utility for symbolizings crash logs for OS X and iOS applications.

In it's essence symbolicator is a wrapper over `atos` command line tool. It's primary focus is making symbolication as simple as possible. As minimum, it's as simple as specifying the list of crash log paths you want to symbolicate:

```
symbolicator crash1.crash ~/Downloads/crash2.crash ~/Documents/crash3.crash

```

The tool will deduce the application information from each crash log, fetch appropriate DWARF file from Xcode archives path and use it to symbolize the crash log.  By default it searches for DWARF files on *~/Library/Developer/Xcode/Archives* but you can specify different path with `--archives` command line switch).

Note: you must run symbolicator on Mac which contains all archived projects for which crash logs belong. If you have multiple crash logs it's faster to provide all of them as multiple arguments on command line than each one separately.


How to compile?
---------------

1. Open `symbolicator.xcworkspace` file in Xcode and compile. 
2. You can find compiled binary on your Xcode derived data path, by default `~/Library/Developer/Xcode/DerivedData/symbolicator-xxxxxxxxxxxxxxxx/build/Products/Debug` (or Release).
3. For simplest usage, copy generated `symbolicator` binary to some location in your PATH (`/usr/bin` for example, use `echo $PATH` in Terminal to see the list of all possible locations).

Note: Symbolicator is implemented in Swift, so it requires Xcode 6+ to compile. It also uses cocoapods for dependencies, for convenience they are included in this repository so you don't need to do `pod install`. Just take care to open `xcworkspace` not `xcodeproj` file!


How it works?
-------------

Each crash log contains information about the application that crashes - this includes name, bundle identifier, version and build number etc. Each Xcode archive is simply a bundle containing both, compiled binary (that's usually stripped of all debugging symbols) and DWARF file which contains all symbol mappings. Additionally, it contains a plist file that describes the application information - version etc. for which it was created. Symbolicator matches information from crash log with corresponding archive bundle and uses it to symbolicate symbols.


Thanks
------

Symbolicator uses the following open source libraries:

- [GBCli](http://github.com/tomaz/GBCli)
- [RX+](http://github.com/bendytree/Objective-C-RegEx-Categories)


License
-------

The code is provided under MIT license as stated below:

	Copyright (C) 2012 by Tomaz Kragelj
	
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.