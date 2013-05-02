# (*) Asterisk 

Asterisk is a Web-based minimistic code editor written in CoffeeScript running on node.js with webSockets.

I made this editor because I want to make my own tools.
I put this out there in hopes that you find it usefull, and maybe contribute.

## Selling points

* *small and simple* you can mold it to your liking.
* *minimalism philosophy* no tabs, bars, panels just code.
* *web-based* host dev tools on one server access from anywhere.
* *webSockets* real time and responsive.
* MIT license.

## Why webbased?

Every thing is moving to the web and I feel that programming will move there too. 
No longer are we confied to a single device but move freely between laptops, desktops and even tablets.
But the web moves with us.
You could have all your tools installed on a server and use VNC to access them. 
VNC is clunky and draw diley and jpeg artafacts are very garring.  
You could opt out to use ssh with vi or emacs. 
But then again just like VNC you need SSH client installed. 
I for one can't stand the input delay and the text mode graphics.  
I want nice fonts and beatuful colors. 
That is why I wrote this editor. 
Free of distractions easy to change to your liking.


## Under the hood

Asterisk devieds into two main parts: the server part asterisk.coffee and client.coffee.

### Client side.

* tokenizer
* editor 
* webcoket connection
* command bars (find, replace, open, other commands)
* key input system 

#### Tokenizer

Simplest syntax highligher there is. Modeld after the Crimpson editor. 
Basic premis is that it needs to be fast and simple. 
Fast because not all devices have CPU cycles to spare and I wnat no delay in rednering.
Simple in order to capture as many langauges as possible easly.
It does not try to parse the langauge grammer entirly it only tries to:

* highlight key words
* highlight strings
* highlight comments

Thats it. The highlight spesification are very simple. 

This is big contrast to CodeMirror - great highlighter that tries to do everything.

#### Editor

Editor it self is just a text area. This text area is hidden and a ghost div is put in place.
This ghost div has all the highliting tags. 
The js keeps the textarea and the ghost div in sync so that any commands done to the textarea (copy, past, undo, and selections) applies exaclty to the ghost div too.
There is another ghost like div that is the carret and the selection.

#### Websoket connection

Handles all the routing and commands to and from the server. Most operation are asyncronos. 
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

Does not work in IE because the work arounds would make it too complex.

- treeform
