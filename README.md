# (*) Asterisk

Asterisk is a Web-based minimalistic code editor written in CoffeeScript running on node.js with WebSockets.

I made this editor because I want to have 100% control over how everything worked. I put it on github because I wanted to link people to it. Its an odd to have the editor.


## Selling points

* *small and simple* you can mold it to your liking.
* *minimalism philosophy* no tabs, bars, panels just code.
* *web-based* host this on your server access from anywhere.
* *WebSockets* real time and responsive.
* MIT license.

## Why web-based?

Every thing is moving to the web and I feel that programming will move there too.
No longer are we confined to a single device but move freely between laptops, desktops and even tablets.
But the web moves with us.
You could have all your tools installed on a server and use VNC to access them.
VNC is clunky and draw delay and jpeg artifacts are very jaring.
You could opt out to use ssh with vi or emacs.
But then again just like VNC you need SSH client installed.
I for one can't stand the input delay and the text font rednering.
I want nice fonts and beautiful colors.
That is why I wrote this editor.


## Under the hood

Asterisk devides into two main parts: the server part asterisk.coffee and client.coffee.

### Client side.

* tokenizer
* editor
* websoket connection
* command UI (find, replace, open, other commands)
* key input system

#### Tokenizer

Simplest syntax highlighter there is. Modeled after the Crimson editor (http://www.crimsoneditor.com/).
The basic premise is that it needs to be fast and simple.
It does not try to parse the language grammar entirely it only tries to:

* highlight key words
* highlight strings
* highlight comments

Thats it. The highlight specification are very simple. Just common keywards and some string and comment matching.

Because it does not parse the full grammer it does not break or flicker as much when type because the sytnax is messedup.
This is big contrast to CodeMirror - great highlighter that tries to do everything.

#### Editor

Editor it self is just a text area. This text area is hidden and a ghost div is put in place.
This ghost <div> has all the highliting tags.
The code keeps the <textarea> and the ghost <div> in sync so that any commands done to the <textarea> (copy, past, undo, and selections) applies exactly to the ghost div too.
There is another ghost like div that is the caret and the selection.

#### Websocket connection

Handles all the routing and commands to and from the server. Most operation are asynchronous.
When you tell the editor to open a file it asks the server to open a file.
Then server responds with an open-push command or open-error command.


### Server side

* static file server
* websoket server
* plugins


### To generate secure folder do this:

mkdir secure
cd secure
openssl genrsa -out privatekey.pem 1024
openssl req -new -key privatekey.pem -out certrequest.csr

after entering your info

openssl x509 -req -in certrequest.csr -signkey privatekey.pem -out certificate.pem

## NO IE

Does not work in IE because the work arounds would make it too complex. Deal with it.
