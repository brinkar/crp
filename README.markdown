Communicating Ruby Processes
============================

*DISCLAIMER* This library is not ready for any serious use.

This is an implementation of features from various process calculi (mostly CSP and Pi-calculus) in Ruby and Eventmachine. What this means for you, as everything else I guess, depends on where you're coming from.

In general this is a library to ease the development of highly concurrent programs in Ruby. More (or less) specifically it makes it possible to create dynamical networks of processes across multiple CPU cores or the network without having to worry about the usual pitfalls of such an endeavour. It does so by introducing a couple of simple contructs: processes and channels. This is inspired by CSP (communicating sequential processes), pi-calculus and implementations hereof such as Occam-pi, JCSP, PyCSP, C++CSP etc.

I won't write any more before this library has proven itself a bit more, but basically you should be interested in this project if you're interested in what makes programming languages such as Erlang, Scala and Go and libraries such as Eventmachine, Twisted, Revactor and Node.js so popular.

Installation
------------

This library will only work on Ruby 1.9.1. Anything before that is a definite no-go (it uses fibers) and Ruby 1.9.2 mostly works with a few itches. If you are frightened by this paragraph, I would suggest you to try out RVM which makes it easy to install different ruby versions side by side.

To install, basically clone this repository and install a couple of gems:
<pre>
git clone http://github.com/brinkar/crp.git
gem install eventmachine yajl
</pre>

Usage
-----

At some point a tutorial might be written and API docs might be generated, but for now you can look in the examples directory to get an idea of the possibilities. Or the library code itself.

Run the examples by doing something like this in the crp directory:
<pre>
ruby -I lib/ examples/simple.rb
</pre>

The tests havn't been updated in a while so don't trust them yet.
