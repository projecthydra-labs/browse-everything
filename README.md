# BrowseEverything

Code:
[![Gem Version](https://badge.fury.io/rb/browse-everything.png)](http://badge.fury.io/rb/browse-everything)
[![CircleCI](https://circleci.com/gh/samvera/browse-everything.svg?style=svg)](https://circleci.com/gh/samvera/browse-everything)
[![Coverage Status](https://coveralls.io/repos/samvera/browse-everything/badge.svg?branch=master&service=github)](https://coveralls.io/github/samvera/browse-everything?branch=master)

Docs:
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE.txt)

Jump in: [![Slack Status](http://slack.samvera.org/badge.svg)](http://slack.samvera.org/)

# What is BrowseEverything?

This Gem allows your rails application to access user files from cloud storage.
Currently there are drivers implemented for [Dropbox](http://www.dropbox.com),
[Google Drive](http://drive.google.com),
[Box](http://www.box.com), [Amazon S3](https://aws.amazon.com/s3/),
and a server-side directory share.

The gem uses [OAuth](http://oauth.net/) to connect to a user's account and
generate a list of single use urls that your application can then use to
download the files.

**This gem does not depend on hydra-head**

## Product Owner & Maintenance

BrowseEverything is a Core Component of the Samvera community. The documentation for
what this means can be found
[here](http://samvera.github.io/core_components.html#requirements-for-a-core-component).

### Product Owner

[mbklein](https://github.com/mbklein)

# Getting Started

## Supported Ruby Releases
Currently, the following releases of Ruby are tested:
- 3.0
- 2.7
- 2.6

## Supported Rails Releases
The supported Rail releases follow those specified by [the security policy of the Rails Community](https://rubyonrails.org/security/).  As is the case with the supported Ruby releases, it is recommended that one upgrades from any Rails release no longer receiving security updates.
- 6.1
- 6.0
- 5.2
- 5.1

## Installation

Add this lines to your application's Gemfile:

    gem 'jquery-rails'
    gem 'browse-everything'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install browse-everything

## Configuring the gem in your host app

After installing the gem, run the generator

    $ rails g browse_everything:install

This generator will set up the _config/browse_everything_providers.yml_ file and add the browse-everything engine to your application's routes.

If you prefer not to use the generator, or need info on how to set up providers in the browse_everything_providers.yml, use the info on [Configuring browse-everything](https://github.com/samvera/browse-everything/wiki/Configuring-browse-everything).

Browse-everything depends on bootstrap, it can work with bootstrap 3 or bootstrap 4.

### CSS

**For bootstrap3 support**, your app should include the [bootstrap-sass](https://github.com/twbs/bootstrap-sass) gem in it's Gemfile, and following the install directions for bootstrap-sass, should have `@import 'bootstrap-sprockets'` and `@import 'bootstrap'` in it's application.scss. After those lines, add `@import "browse_everything/browse_everything_bootstrap3";` to your application.scss.

**For bootstrap4 support**, your app should include the [bootstrap](https://github.com/twbs/bootstrap-rubygem) gem in it's Gemfile, and following the install directions for that gem should have `@import "bootstrap";` in it's application.scss. After that line, add `@import 'browse_everything/browse_everything_bootstrap4'` to your application.scss.

### Javascript

In `app/assets/javascripts/application.js` include jquery and the BrowseEverything

```javascript
//= require jquery
//= require browse_everything
```

(Same for bootstrap3 or bootstrap 4)

### Migration CSS inclusion from pre-1.0

If your app has installed a previous version of browse-everything, you may have a generated file at `./app/assets/stylesheets/browse_everything.scss`, which has a line in it `@import "browse_everything/browse_everything";`.  That import should no longer be used; it can be changed to `@import "browse_everything/browse_everything_bootstrap3"` instead.

However, we also recommend merging the contents of this file into your main `application.scss` file, as documented in the current install instructions. With the separate generated file with bootstrap imports, you may likely be including bootstrap CSS in your generated CSS bundle twice, if you also have that import in your main application.scss already.

## Testing
This is a Rails Engine which is tested using the [engine_cart](https://github.com/cbeer/engine_cart) Gem and rspec.

One rspec test invokes [karma](https://karma-runner.github.io/latest/index.html) to run Javascript tests. For this test to succeed, you need to install karma on your system, first by making sure `npm` is installed, and then run `npm install -g karma karma-jasmine karma-chrome-launcher`.

Test suites may be executed with the following invocation:

```bash
bundle exec rake
```

Tests by default will be run with bootstrap-4 integration. To test bootstrap-3 integration: `TEST_BOOTSTRAP=3 bundle exec rake`.

### Testing Problems
Should you attempt to execute the test suite and encounter the following error:
```bash
Your Ruby version is 2.x.x, but your Gemfile specified 2.y.z
```
...then you must clean the internal test app generated by `engine_cart` with the following:
```bash
bundle exec rake engine_cart:clean
```

## Usage

### Adding Providers
In order to connect to a provider like [Dropbox](http://www.dropbox.com),
[Google Drive](http://drive.google.com), or
[Box](http://www.box.com), you must provide API keys in _config/browse_everything_providers.yml_.  For info on how to edit this file, see [Configuring browse-everything](https://github.com/samvera/browse-everything/wiki/Configuring-browse-everything)

### Views

browse-everything can be triggered in two ways -- either via data attributes in an HTML tag or via JavaScript.  Either way, it accepts the same options:

#### Options

| Name            | Type            | Default         | Description |
|-----------------|-----------------|-----------------|----------------------------------------------------------------|
| route           | path (required) | ''              | The base route of the browse-everything engine.                |
| target          | xpath or jQuery | null            | A form object to add the results to as hidden fields.          |
| context         | text            | null            | App-specific context information (passed with each request)    |
| accept          | MIME mask       | */*             | A list of acceptable MIME types to browse (e.g., 'video/*')    |

If a `target` is provided, browse-everything will automatically convert the JSON response to a series of hidden form fields
that can be posted back to Rails to re-create the array on the server side.

#### Via data attributes

To trigger browse-everything using data attributes, set the _data-toggle_ attribute to "browse-everything" on the HTML tag.  This tells the javascript where to attach the browse-everything behaviors. Pass in the options using the _data-route_ and _data-target_ attributes, as in `data-target="#myForm"`.

For example:

```html
<button type="button" data-toggle="browse-everything" data-route="<%=browse_everything_engine.root_path%>"
  data-target="#myForm" class="btn btn-large btn-success" id="browse">Browse!</button>
```

#### Via JavaScript

To trigger browse-everything via javascript, use the .browseEverything() method to attach the behaviors to DOM elements.

```javascript
$('#browse').browseEverything(options)
```

The options argument should be a JSON object with the route and (optionally) target values set.  For example:
```javascript
$('#browse').browseEverything({
  route: "/browse",
  target: "#myForm"
})
```

See [JavaScript Methods](https://github.com/samvera/browse-everything/wiki/JavaScript-Methods) for more info on using javascript to trigger browse-everything.

### The Results (Data Structure)

browse-everything returns a JSON data structure consisting of an array of URL specifications. Each URL specification
is a plain object with the following properties:

| Property           | Description |
|--------------------|--------------------------------------------------------------------------------------|
| url                | The URL of the selected remote file. |
| auth_header        | Any headers that need to be added to the request in order to access the remote file. |
| expires            | The expiration date/time of the specified URL. |
| file_name          | The base name (filename.ext) of the selected file.                                   |

For example, after picking two files from dropbox,

If you initialized browse-everything via JavaScript, the results data passed to the `.done()` callback will look like this:
```json
[
  {
    "url": "https://dl.dropbox.com/fake/filepicker-demo.txt.txt",
    "expires": "2014-03-31T20:37:36.214Z",
    "file_name": "filepicker-demo.txt.txt"
  }, {
    "url": "https://dl.dropbox.com/fake/Getting%20Started.pdf",
    "expires": "2014-03-31T20:37:36.731Z",
    "file_name": "Getting Started.pdf"
  }
]
```
See [JavaScript Methods](https://github.com/samvera/browse-everything/wiki/JavaScript-Methods) for more info on using javascript to trigger browse-everything.

If you initialized browse-everything via data-attributes and set the _target_ option (via the _data-target_ attribute or via the _target_ option on the javascript method), the results data be written as hidden fields in the `<form>` you've specified as the target.  When the user submits that form, the results will look like this:
```ruby
"selected_files" => {
  "0"=>{
    "url"=>"https://dl.dropbox.com/fake/filepicker-demo.txt.txt",
    "expires"=>"2014-03-31T20:37:36.214Z",
    "file_name"=>"filepicker-demo.txt.txt"
  },
  "1"=>{
    "url"=>"https://dl.dropbox.com/fake/Getting%20Started.pdf",
    "expires"=>"2014-03-31T20:37:36.731Z",
    "file_name"=>"Getting Started.pdf"
  }
}
```

### Retrieving Files

The `BrowseEverything::Retriever` class has two methods, `#retrieve` and `#download`, that
can be used to retrieve selected content. `#retrieve` streams the file by yielding it, chunk
by chunk, to a block, while `#download` saves it to a local file.

Given the above response data:

```ruby
retriever = BrowseEverything::Retriever.new
download_spec = params['selected_files']['1']

# Retrieve the file, yielding each chunk to a block
retriever.retrieve(download_spec) do |chunk, retrieved, total|
  # do something with the `chunk` of data received, and/or
  # display some progress using `retrieved` and `total` bytes.
end

# Download the file. If `target_file` isn't specified, the
# retriever will create a tempfile and return the name.
retriever.download(download_spec, target_file) do |filename, retrieved, total|
  # The block is still useful for showing progress, but the
  # first argument is the filename instead of a chunk of data.
end
```

### Examples

See `spec/support/app/views/file_handler/index.html` for an example use case. You can also run `rake app:generate` to
create a fully-functioning demo app in `spec/internal` (though you will have to create
`spec/internal/config/browse_everything.providers.yml` file with your own configuration info.)

# Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

# Acknowledgments

This software has been developed by and is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://wiki.duraspace.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)
