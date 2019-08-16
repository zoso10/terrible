# frozen_string_literal: true

require "pry-byebug"
require "puma"
require "rack"
require "json"

class Application
  USERS_PATH = "/users"

  def self.call(env)
    new(env).call
  end

  def initialize(env)
    @env = env
  end

  def call
    if env[Rack::REQUEST_METHOD] == Rack::POST && env[Rack::PATH_INFO] == USERS_PATH
      body = env[Rack::RACK_INPUT].read
      body_json = JSON.parse(body)
      body_data = body_json.map { |key, value| "#{key}:#{value}" }.join(",")
      File.open(__FILE__, "a") do |file|
        file.write("# #{body_data}\n")
      end
      [
        201,
        { Rack::CONTENT_TYPE => "text/plain", Rack::CONTENT_LENGTH => "2" },
        ["OK"],
      ]
    elsif env[Rack::REQUEST_METHOD] == Rack::GET && env[Rack::PATH_INFO].match?(/#{USERS_PATH}\/\d+/)
      id = env[Rack::REQUEST_PATH].gsub("/users/", "")
      file = File.new(__FILE__)
      file.gets("DATA_BEGIN\n")
      all_data = file.read.split("\n")
      user_data = all_data.find { |line| line.include?("id:#{id}") }

      if user_data.nil?
        [
          404,
          { Rack::CONTENT_TYPE => "text/plain", Rack::CONTENT_LENGTH => "9" },
          ["Not Found"],
        ]
      else
        user_hash = user_data.gsub("# ", "").split(",").map { |el| el.split(":") }.to_h
        user_json = JSON.dump({ user: user_hash })

        [
          200,
          { Rack::CONTENT_TYPE => "application/json" },
          [user_json],
        ]
      end
    else
      [
        404,
        { Rack::CONTENT_TYPE => "text/plain", Rack::CONTENT_LENGTH => "9" },
        ["Not Found"],
      ]
    end

  end

  private

  attr_reader :env
end

run Application

# DATA_BEGIN
# id:123,name:Tyler Ewing
# id:456,name:Alex
# id:789,name:Patrick
