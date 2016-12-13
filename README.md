# bigpack bundle up recursive dependencies of a NPM packge

# Deprecation Warning

Two things that make me think this project is actually a stupid idea.

One reason is a misunderstanding that cost me several days: 
There was a [regression](https://github.com/npm/npm/issues/13088) in NPM that completely confused me.
In fact, `npm pack` *is actually supposed* to include the recursive dependenceis of all `bundledDependencies`.
It just wasn't working correctly in the particular version I was using.

The second reason is that I recently came to understand that my approach of creating an entirely new
package instead of modifying the original one was a flawed one to begin with.
My (valid, I think) motivation was to avoid conflicts with the original package.
But creating a separate package (with a separate name) causes all sort of other difficulties (see Issues #2 and #3).

Realizing that simply adding the *direct* dependencies to the list of
`bundledDependencies` solves most if not all of my problems, I see not much point in
going through all the trouble. I will instead try something arround the lines of 
[bundled-dependencies](https://www.npmjs.com/package/bundled-dependencies)
and let it update my `package.json` file on every build.
The only thing I might be inclined to add is checking if updating the file is
necessary at all.



## This tool solves a very particular use case:

I have a production environment running some variant of MS Windows. Networking
policies are rather restrictive, in particular I cannot connect to the NPM
registry.

I use a mix of published and private NPM packages.

I cannot publish those private NPMs and I do not want to run my own registry.

To install a package on production, I want to create a single bundle that
creates that package aswell as the transitive closure of all its dependencies.
I want this bundle to be an npm pack file itself, so I can use the `npm`
executable to unpack and install it in production.

This is clearly not the most elegant solution. If you solveds a similar problem
in a different way, please drop me a note.


# Yet another one?

There are different solutions. `npmbox` in particular does not look bad at all,
but it seems it has a slightly different focus. Or maybe I didn't completely
understand how it was inteded to work. Anyway, what I needed seemed simple
enough, so I tried it myself, also to get a better understanding of the problem
itself.

# Install

You *could* install it globally via `npm install -g bigpack`.  However, I
prefer adding it as a dev-dependency to whatever package I want to bundle up.

``` 
bash npm install --save-dev bigpack 
```

Then you can add a `script` entry in your `package.json` to actually use the script.

# Usage:

There isn't much of a CLI right now. Assuming you are at the root of the project you want to bundle,
just run `bigpack`. It will take a moment (no progress indication, sorry!) and then create
a file `<project-name>-bigpack-<version>.tgz`.

You can install this file via `npm install`.  Note that `npm install` will try
to connect to the registry, even if you run it with `--no-registry`.  It does
not *need* anything from the registry, though. It will just sit there waiting
for the connection to timeout, and then it will continue normally.

To escape this madness, here is what I usually do:

```

npm --fetch-retries=0 install <project-name>-bigpack-<version>.tgz

```

As I said: there may be more elegant solutions...
