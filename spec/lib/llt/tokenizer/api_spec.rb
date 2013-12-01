ENV['RACK_ENV'] = 'test'

require 'spec_helper'
require 'llt/tokenizer/api'
require 'rack/test'

def app
  Api
end

describe "tokenizer api" do
  include Rack::Test::Methods

  describe '/tokenize' do
    context "with URI as input" do
      it "responds to GET" do
        get '/tokenize'
        last_response.should be_ok
      end
    end

    let(:text) {{text: "homo mittit."}}

    context "with text as input" do
      context "with accept header json" do
        it "segments the given text" do
          pending
          get '/tokenize', text,
            {"HTTP_ACCEPT" => "application/json"}
          last_response.should be_ok
          response = last_response.body
          parsed_response = JSON.parse(response)
          parsed_response.should have(3).items
        end
      end

      context "with accept header xml" do
        it "tokenize the given text" do
          get '/tokenize', text,
            {"HTTP_ACCEPT" => "application/xml"}
          last_response.should be_ok
          body = last_response.body
          body.should =~ /<w>homo<\/w>/
          body.should =~ /<w>mittit<\/w>/
          body.should =~ /<pc>\.<\/pc>/
        end

        it "receives params for tokenization and markup" do
          params = { indexing: true }.merge(text)

          get '/tokenize', params,
            {"HTTP_ACCEPT" => "application/xml"}
          last_response.should be_ok
          body = last_response.body
          body.should =~ /<w n="1">homo<\/w>/
          body.should =~ /<w n="2">mittit<\/w>/
          body.should =~ /<pc n="3">\.<\/pc>/
        end
      end
    end
  end
end
