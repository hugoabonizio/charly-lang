require "../helper.cr"
require "../file.cr"
require "./location.cr"
require "../interpreter/stack/stack.cr"

module Charly::Parser::AST
  abstract class ASTNode
    property children : Array(ASTNode)

    # The location where this node begins
    property! location : Location?

    # The location where this node ends
    property! location_end : Location?

    def initialize
      @children = [] of ASTNode
    end

    def at(start)
      @location = start
      return self
    end

    def at(from start, to end)
      @location = start
      @end = end
      return self
    end

    # Appends *node* to the children of this node
    def <<(node)
      @children << node
    end

    def size
      @children.size
    end

    def [](index)
      @children[index]
    end

    # Correct the parent pointers of all children
    def children=(new_children)
      @children = new_children
    end

    # Render the current node
    def to_s(io)

      if (meta = info).size > 0
        io << meta
      else
        io << "#{self.class.name.split("::").last}"
      end
      io << "\n"

      children.each do |child|
        lines = child.to_s.each_line.each
        lines.each do |line|
          if !['┣', '┃'].includes?(line[0])
            io << line.indent(1, "┣╸")
          elsif line.size > 0
            io << line.indent(1, "┃ ")
          end
        end
      end
    end

    def info
      ""
    end
  end

  macro ast_node(name, *properties)
    class {{name.id}} < ASTNode
      {% for property in properties %}
        {% if property.is_a?(Assign) %}
          property {{property.target.id}}
        {% elsif property.is_a?(TypeDeclaration) %}
          property {{property.var}} : {{property.type}}
        {% else %}
          property :{{property.id}}
        {% end %}
      {% end %}

      {% if properties.size == 0 %}
        def initialize(@children = [] of ASTNode)
        end
      {% else %}
        def initialize({{
          *properties.map do |field|
            "@#{field.id}".id
          end
        }})
          arg = [{{
            *properties.map do |field|
              field.var
            end
          }}] of ASTNode | TokenType

          tmp_children = [] of ASTNode

          arg.each do |field|
            tmp_children << field if field.is_a? ASTNode
          end

          @children = tmp_children
        end
      {% end %}

      {{yield}}
    end
  end

  ast_node Program,
    block : Block

  ast_node Empty
  ast_node Block
  ast_node Statement

  ast_node IfStatement,
    test : ASTNode,
    consequent : Block,
    alternate : ASTNode

  ast_node WhileStatement,
    test : ASTNode,
    consequent : Block

  ast_node Group
  ast_node Expression

  ast_node UnaryExpression,
    operator : TokenType,
    right : ASTNode

  ast_node BinaryExpression,
    operator : TokenType,
    left : ASTNode,
    right : ASTNode do

      def info
        "#{@operator}"
      end
    end

  ast_node ComparisonExpression,
    operator : TokenType,
    left : ASTNode,
    right : ASTNode do

      def info
        "#{@operator}"
      end
    end

  ast_node And,
    left : ASTNode,
    right : ASTNode

  ast_node Or,
    left : ASTNode,
    right : ASTNode

  ast_node VariableDeclaration,
    identifier : IdentifierLiteral

  ast_node VariableInitialisation,
    identifier : IdentifierLiteral,
    expression : ASTNode

  ast_node ConstantInitialisation,
    identifier : IdentifierLiteral,
    expression : ASTNode

  ast_node VariableAssignment,
    identifier : ASTNode,
    expression : ASTNode

  ast_node CallExpression,
    identifier : ASTNode,
    argumentlist : ExpressionList

  ast_node MemberExpression,
    identifier : ASTNode,
    member : IdentifierLiteral

  ast_node IndexExpression,
    identifier : ASTNode,
    member : ASTNode

  ast_node ExpressionList
  ast_node IdentifierList

  ast_node ReturnStatement,
    expression : ASTNode

  ast_node ThrowStatement,
    expression : ASTNode

  ast_node BreakStatement

  ast_node TryCatchStatement,
    try_block : Block,
    exception_name : IdentifierLiteral,
    catch_block : Block

  ast_node NullLiteral
  ast_node NANLiteral
  ast_node IdentifierLiteral,
    name : String do
      def initialize(@name : String)
        @children = [] of ASTNode
      end

      def info
        "#{@name}"
      end
    end

  ast_node StringLiteral,
    value : String do
      def initialize(@value : String)
        @children = [] of ASTNode
      end

      def info
        "#{@value}"
      end
    end

  ast_node NumericLiteral,
    value : Float64 do
      def initialize(@value : Float64)
        @children = [] of ASTNode
      end

      def info
        "#{@value}"
      end
    end

  ast_node KeywordLiteral,
    name : String do
      def initialize(@name : String)
        @children = [] of ASTNode
      end

      def info
        "#{@name}"
      end
    end

  ast_node BooleanLiteral,
    value : Bool do
      def initialize(@value : Bool)
        @children = [] of ASTNode
      end

      def info
        "#{@value}"
      end
    end

  ast_node ArrayLiteral

  ast_node FunctionLiteral,
    argumentlist : IdentifierList,
    block : Block

  ast_node ContainerLiteral,
    block : Block

  ast_node ClassLiteral,
    block : Block

  ast_node LeftParenLiteral
  ast_node RightParenLiteral
  ast_node LeftCurlyLiteral
  ast_node RightCurlyLiteral
  ast_node LeftBracketLiteral
  ast_node RightBracketLiteral

  # Punctuators
  ast_node SemicolonLiteral
  ast_node CommaLiteral
  ast_node PointLiteral
end
