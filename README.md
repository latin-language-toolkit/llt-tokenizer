# LLT::Tokenizer

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'llt-tokenizer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install llt-tokenizer

## Usage

The LLT's Tokenizer makes use of stem dictionaries. Refer to [these instructions](http://github.com/latin-language-toolkit/llt-db_handler "llt-db_handler") on how to set one up.

```ruby
  require 'llt/tokenizer'
 
  tokenizer = LLT::Tokenizer.new
  tokens = tokenizer.tokenize('Arma virumque cano.')
  tokens.map(&:to_s)
  # => ["Arma", "-que", "virum", "cano", "."]
```

The Tokenizer takes several options upon creation or a call to #tokenize:

```ruby
  # shifting determines if enclitics shall be moved to
  # their functional position
  tokenizer = LLT::Tokenizer.new(shifting: false)
  tokens = tokenizer.tokenize('In eoque arma virumque cano.')
  tokens.map(&:to_s)
  # => ["-que", "In", "eo", "arma", "-que", "virum", "cano", "."]
  
  # all options can be passed directly to #tokenize to override
  # the default options
  tokens = tokenizer.tokenize('in eoque arma virumque cano.')
  tokens.map(&:to_s)
  # => ["in", "eo", "-que", "arma", "virum", "-que", "cano", "."]
  
  # enclitics_marker takes a string, which marks up splitted enclitics
  tokenizer = LLT::Tokenizer.new(enclitics_marker: '--', shifting: false)
  tokens = tokenizer.tokenize('Arma virumque cano.')
  tokens.map(&:to_s)
  # => ["Arma", "virum", "--que", "cano", "."]

  # indexing determines if each token shall receive a consecutive id
  tokens = tokenizer.tokenize('Arma virumque cano.', indexing: true)
  tokens.first.id # => 1
  tokens = tokenizer.tokenize('Arma virumque cano.', indexing: false)
  tokens.first.id # => nil

  # merging enables token merging of lemmata, that often appear with
  # orthographical inconsistencies
  tokens = tokenizer.tokenizer('Quam diu cano?', merging: true)
  tokens.map(&:to_s)
  # => ["Quamdiu", "cano", "?"]
```

The returned items are instances of LLT::Token, which can be marked up
in a variety of forms:

```ruby
  tokenizer = LLT::Tokenizer.new(shifting: false, indexing: true)
  tokens = tokenizer.tokenize('Arma virumque cano.')
  tokens.map(&:to_xml)
  # => ["<w>arma<_w>", "<w>virum<_w>", "<w>-que<_w>", "<w>cano<_w>", "<pc>.<_pc>"]
```

Standard TEI XML markup is used: w tags for word tokens, pc tags for
punctuation. The #to_xml method is highly flexible as well, for full
coverage see _TODO_.

```ruby
  puts tokens.map { |token| token.to_xml(indexing: true) }
  # <w n="1">Arma</w>
  # <w n="2">virum</w>
  # <w n="3">-que</w>
  # <w n="4">cano</w>
  # <pc n="5">.</pc>
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
