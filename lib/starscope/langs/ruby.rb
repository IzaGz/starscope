require "parser/current"

module StarScope::Lang
  module Ruby
    def self.match_file(name)
      name =~ /.*\.rb/
    end

    def self.extract(file, &block)
      begin
        ast = Parser::CurrentRuby.parse_file(file)
      rescue
      else
        Extractor.new(ast).extract &block
      end
    end

    private

    class Extractor
      def initialize(ast)
        @ast = ast
        @scope = []
      end
      
      def extract(&block)
        extract_tree(@ast, &block)
      end

      private

      def extract_tree(tree, &block)
        extract_node tree, &block

        new_scope = []
        if [:class, :module].include? tree.type
          new_scope = scoped_name(tree.children[0])
          @scope += new_scope
        end

        tree.children.each {|node| extract_tree node, &block if node.is_a? AST::Node}

        @scope.pop(new_scope.count)
      end

      def extract_node(node)
        if node.type == :send
          yield :calls, scoped_name(node), node.source_map.expression.line

          if node.children[0].nil? and node.children[1] == :require and node.children[2].type == :str
            yield :includes, node.children[2].children[0].split("/"), node.source_map.expression.line
          end
        end

        if node.type == :def
          yield :def, @scope + [node.children[0]], node.source_map.expression.line
        elsif [:module, :class].include? node.type
          yield :def, @scope + scoped_name(node.children[0]), node.source_map.expression.line
        end

        if node.type == :cdecl
          yield :assign, scoped_name(node), node.source_map.expression.line
        elsif [:lvasgn, :ivasgn, :cvdecl, :cvasgn, :gvasgn].include? node.type
          yield :assign, @scope + [node.children[0]], node.source_map.expression.line
        end
      end

      def scoped_name(node)
        if node.type == :block
          scoped_name(node.children[0])
        elsif [:lvar, :ivar, :cvar, :gvar, :const, :send, :cdecl].include? node.type
          if node.children[0].is_a? Symbol
            [node.children[0]]
          elsif node.children[0].is_a? AST::Node
            scoped_name(node.children[0]) << node.children[1]
          elsif node.children[0].nil?
            if node.type == :const
              [node.children[1]]
            else
              @scope + [node.children[1]]
            end
          end
        else
          [node.type]
        end
      end
    end
  end
end
