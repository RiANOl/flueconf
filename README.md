# Flueconf

Config fluentd in ruby
And featuring all programming features (variables, iterators, functions, regexp, etc) in ruby.

[![Gem Version](https://badge.fury.io/rb/flueconf.svg)](https://badge.fury.io/rb/flueconf)
[![Build Status](https://travis-ci.org/RiANOl/flueconf.svg?branch=master)](https://travis-ci.org/RiANOl/flueconf)

## Installation

Add the following lines to Gemfile:

    gem 'flueconf'

And execute:

    $ bundle install

Or just install directly by:

    $ gem install flueconf

## Usage

```ruby
dir_permission = '0755'
forward_hosts = %w(192.0.2.1 192.0.2.2)

builder = Flueconf.build do
  system do
    dir_permission dir_permission
  end
  filter 'fluent.**' do
    type 'record_transformer'
    record do
      level '${tag_parts[1]}'
      hostname '#{Socket.gethostname}'
    end
  end
  match 'fluent.**' do
    type 'rewrite_tag_filter'
    rule do
      key 'message'
      pattern /.*/
      tag 'fluent'
    end
  end
  match '**' do
    forward_hosts.each do |h|
      server do
        host h
      end
    end
  end
end

builder.build do
  source do
    type 'forward'
    id 'in_forward'
    label '@forward'
    port 24224
  end
  label '@forward' do
    match '**' do
      type 'forward'
      forward_hosts.each do |h|
        server do
          host h
        end
      end
    end
  end
end

puts builder.to_fluent
```

will output:

```
<system>
  dir_permission 0755
</system>
<source>
  @type forward
  @id in_forward
  @label @outside
  port 24224
</source>
<filter fluent.**>
  @type record_transformer
  <record>
    level ${tag_parts[1]}
    hostname "#{Socket.gethostname}"
  </record>
</filter>
<match fluent.**>
  @type rewrite_tag_filter
  <rule>
    key message
    pattern (?-mix:.*)
    tag fluent
  </rule>
</match>
<match **>
  <server>
    host 192.0.2.1
  </server>
  <server>
    host 192.0.2.2
  </server>
</match>
<label @forward>
  <match **>
    @type forward
    <server>
      host 192.0.2.1
    </server>
    <server>
      host 192.0.2.2
    </server>
  </match>
</label>
```

And you also can use the following style to avoid conflicted name or change indentation:

```ruby
builder = Flueconf.build do
  add :source do
    add :@type, 'forward'
    add :port, 24224
  end
end

puts builder.to_fluent(indent: 4)
```

will output:

```
<source>
    @type forward
    port 24224
</source>
```
