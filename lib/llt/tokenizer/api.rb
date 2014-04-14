require 'sinatra/base'
require 'sinatra/respond_with'
require 'llt/tokenizer'
require 'llt/core/api'

class Api < Sinatra::Base
  register Sinatra::RespondWith
  register LLT::Core::Api::VersionRoutes
  helpers LLT::Core::Api::Helpers

  get '/tokenize' do
    typecast_params!(params)
    text = extract_text(params)
    tokenizer = LLT::Tokenizer.new(params)
    tokens = tokenizer.tokenize(text)

    respond_to do |f|
      f.xml { to_xml(tokens, params) }
    end
  end

  add_version_route_for('/tokenize', dependencies: %i{ Core Tokenizer })
end
