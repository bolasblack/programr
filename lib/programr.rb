require 'yaml'
require 'rexml/parsers/sax2parser'
require 'active_support/core_ext/string'

require "programr/version"
require 'programr/graphmaster'
require 'programr/graph_node'
require 'programr/environment'
require 'programr/aiml_elements'
require 'programr/aiml_parser'
require 'programr/history'
require 'programr/facade'

module ProgramR
  module GraphMark
    THAT  = '<that>'
    TOPIC = '<topic>'
    ALL = [THAT, TOPIC]
  end
end
