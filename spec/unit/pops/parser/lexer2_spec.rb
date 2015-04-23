require 'spec_helper'
require 'matchers/match_tokens2'
require 'puppet/pops'
require 'puppet/pops/parser/lexer2'

module EgrammarLexer2Spec
  def tokens_scanned_from(s)
    lexer = Puppet::Pops::Parser::Lexer2.new
    lexer.string = s
    tokens = lexer.fullscan[0..-2]
  end

  def epp_tokens_scanned_from(s)
    lexer = Puppet::Pops::Parser::Lexer2.new
    lexer.string = s
    tokens = lexer.fullscan_epp[0..-2]
  end
end

describe 'Lexer2' do
  include EgrammarLexer2Spec

  {
    :LISTSTART => '[',
    :RBRACK => ']',
    :LBRACE => '{',
    :RBRACE => '}',
    :LPAREN => '(',
    :RPAREN => ')',
    :EQUALS => '=',
    :ISEQUAL => '==',
    :GREATEREQUAL => '>=',
    :GREATERTHAN => '>',
    :LESSTHAN => '<',
    :LESSEQUAL => '<=',
    :NOTEQUAL => '!=',
    :NOT => '!',
    :COMMA => ',',
    :DOT => '.',
    :COLON => ':',
    :AT => '@',
    :LLCOLLECT => '<<|',
    :RRCOLLECT => '|>>',
    :LCOLLECT => '<|',
    :RCOLLECT => '|>',
    :SEMIC => ';',
    :QMARK => '?',
    :OTHER => '\\',
    :FARROW => '=>',
    :PARROW => '+>',
    :APPENDS => '+=',
    :DELETES => '-=',
    :PLUS => '+',
    :MINUS => '-',
    :DIV => '/',
    :TIMES => '*',
    :LSHIFT => '<<',
    :RSHIFT => '>>',
    :MATCH => '=~',
    :NOMATCH => '!~',
    :IN_EDGE => '->',
    :OUT_EDGE => '<-',
    :IN_EDGE_SUB => '~>',
    :OUT_EDGE_SUB => '<~',
    :PIPE => '|',
  }.each do |name, string|
    it "should lex a token named #{name.to_s}" do
      expect(tokens_scanned_from(string)).to match_tokens2(name)
    end
  end

  it "should lex [ in position after non whitespace as LBRACK" do
    expect(tokens_scanned_from("a[")).to match_tokens2(:NAME, :LBRACK)
  end

  {
    "case"     => :CASE,
    "class"    => :CLASS,
    "default"  => :DEFAULT,
    "define"   => :DEFINE,
#    "import" => :IMPORT, # done as a function in egrammar
    "if"       => :IF,
    "elsif"    => :ELSIF,
    "else"     => :ELSE,
    "inherits" => :INHERITS,
    "node"     => :NODE,
    "and"      => :AND,
    "or"       => :OR,
    "undef"    => :UNDEF,
    "false"    => :BOOLEAN,
    "true"     => :BOOLEAN,
    "in"       => :IN,
    "unless"   => :UNLESS,
  }.each do |string, name|
    it "should lex a keyword from '#{string}'" do
      expect(tokens_scanned_from(string)).to match_tokens2(name)
    end
  end

  # TODO: Complete with all edge cases
  [ 'A', 'A::B', '::A', '::A::B',].each do |string|
    it "should lex a CLASSREF on the form '#{string}'" do
      expect(tokens_scanned_from(string)).to match_tokens2([:CLASSREF, string])
    end
  end

  # TODO: Complete with all edge cases
  [ 'a', 'a::b', '::a', '::a::b',].each do |string|
    it "should lex a NAME on the form '#{string}'" do
      expect(tokens_scanned_from(string)).to match_tokens2([:NAME, string])
    end
  end

  [ 'a-b', 'a--b', 'a-b-c', '_x'].each do |string|
    it "should lex a BARE WORD STRING on the form '#{string}'" do
      expect(tokens_scanned_from(string)).to match_tokens2([:WORD, string])
    end
  end

  [ '_x::y', 'x::_y'].each do |string|
    it "should consider the bare word '#{string}' to be a WORD" do
      expect(tokens_scanned_from(string)).to match_tokens2(:WORD)
    end
  end

  { '-a'   =>      [:MINUS, :NAME],
    '--a'  =>      [:MINUS, :MINUS, :NAME],
    'a-'   =>      [:NAME, :MINUS],
    'a- b'   =>    [:NAME, :MINUS, :NAME],
    'a--'  =>      [:NAME, :MINUS, :MINUS],
    'a-$3' =>      [:NAME, :MINUS, :VARIABLE],
  }.each do |source, expected|
    it "should lex leading and trailing hyphens from #{source}" do
      expect(tokens_scanned_from(source)).to match_tokens2(*expected)
    end
  end

  { 'false'=>false, 'true'=>true}.each do |string, value|
    it "should lex a BOOLEAN on the form '#{string}'" do
      expect(tokens_scanned_from(string)).to match_tokens2([:BOOLEAN, value])
    end
  end

  [ '0', '1', '2982383139'].each do |string|
    it "should lex a decimal integer NUMBER on the form '#{string}'" do
      expect(tokens_scanned_from(string)).to match_tokens2([:NUMBER, string])
    end
  end

  { ' 1' => '1', '1 ' => '1', ' 1 ' => '1'}.each do |string, value|
    it "should lex a NUMBER with surrounding space '#{string}'" do
      expect(tokens_scanned_from(string)).to match_tokens2([:NUMBER, value])
    end
  end

  [ '0.0', '0.1', '0.2982383139', '29823.235', '10e23', '10e-23', '1.234e23'].each do |string|
    it "should lex a decimal floating point NUMBER on the form '#{string}'" do
      expect(tokens_scanned_from(string)).to match_tokens2([:NUMBER, string])
    end
  end

  [ '00', '01', '0123', '0777'].each do |string|
    it "should lex an octal integer NUMBER on the form '#{string}'" do
      expect(tokens_scanned_from(string)).to match_tokens2([:NUMBER, string])
    end
  end

  [ '0x0', '0x1', '0xa', '0xA', '0xabcdef', '0xABCDEF'].each do |string|
    it "should lex an hex integer NUMBER on the form '#{string}'" do
      expect(tokens_scanned_from(string)).to match_tokens2([:NUMBER, string])
    end
  end

  { "''"      => '',
    "'a'"     => 'a',
    "'a\\'b'" =>"a'b",
    "'a\\rb'" =>"a\\rb",
    "'a\\nb'" =>"a\\nb",
    "'a\\tb'" =>"a\\tb",
    "'a\\sb'" =>"a\\sb",
    "'a\\$b'" =>"a\\$b",
    "'a\\\"b'" =>"a\\\"b",
    "'a\\\\b'" =>"a\\b",
    "'a\\\\'" =>"a\\",
  }.each do |source, expected|
    it "should lex a single quoted STRING on the form #{source}" do
      expect(tokens_scanned_from(source)).to match_tokens2([:STRING, expected])
    end
  end

  { "''"      => [2, ""],
    "'a'"     => [3, "a"],
    "'a\\'b'" => [6, "a'b"],
    }.each do |source, expected|
      it "should lex a single quoted STRING on the form #{source} as having length #{expected[0]}" do
       length, value = expected
       expect(tokens_scanned_from(source)).to match_tokens2([:STRING, value, {:line => 1, :pos=>1, :length=> length}])
      end
    end

  { '""'      => '',
    '"a"'     => 'a',
    '"a\'b"'  => "a'b",
  }.each do |source, expected|
    it "should lex a double quoted STRING on the form #{source}" do
      expect(tokens_scanned_from(source)).to match_tokens2([:STRING, expected])
    end
  end

  { '"a$x b"'     => [[:DQPRE,    'a',   {:line => 1, :pos=>1, :length=>2 }],
                      [:VARIABLE, 'x',   {:line => 1, :pos=>3, :length=>2 }],
                      [:DQPOST,   ' b',  {:line => 1, :pos=>5, :length=>3 }]],

    '"a$x.b"'     => [[:DQPRE,    'a',   {:line => 1, :pos=>1, :length=>2 }],
                      [:VARIABLE, 'x',   {:line => 1, :pos=>3, :length=>2 }],
                      [:DQPOST,   '.b',  {:line => 1, :pos=>5, :length=>3 }]],

    '"$x.b"'      => [[:DQPRE,    '',    {:line => 1, :pos=>1, :length=>1 }],
                      [:VARIABLE, 'x',   {:line => 1, :pos=>2, :length=>2 }],
                      [:DQPOST,   '.b',  {:line => 1, :pos=>4, :length=>3 }]],

    '"a$x"'       => [[:DQPRE,    'a',   {:line => 1, :pos=>1, :length=>2 }],
                      [:VARIABLE, 'x',   {:line => 1, :pos=>3, :length=>2 }],
                      [:DQPOST,   '',    {:line => 1, :pos=>5, :length=>1 }]],

    '"a${x}"'     => [[:DQPRE,    'a',   {:line => 1, :pos=>1, :length=>4 }],
                      [:VARIABLE, 'x',   {:line => 1, :pos=>5, :length=>1 }],
                      [:DQPOST,   '',    {:line => 1, :pos=>7, :length=>1 }]],

    '"a${_x}"'    => [[:DQPRE,    'a',   {:line => 1, :pos=>1, :length=>4 }],
                      [:VARIABLE, '_x',  {:line => 1, :pos=>5, :length=>2 }],
                      [:DQPOST,   '',    {:line => 1, :pos=>8, :length=>1 }]],

    '"a${y::_x}"' => [[:DQPRE,    'a',   {:line => 1, :pos=>1, :length=>4 }],
                      [:VARIABLE, 'y::_x',  {:line => 1, :pos=>5, :length=>5 }],
                      [:DQPOST,   '',    {:line => 1, :pos=>11, :length=>1 }]],

    '"a${_x[1]}"' => [[:DQPRE,    'a',   {:line => 1, :pos=>1, :length=>4 }],
                      [:VARIABLE, '_x',  {:line => 1, :pos=>5, :length=>2 }],
                      [:LBRACK,   '[',   {:line => 1, :pos=>7, :length=>1 }],
                      [:NUMBER,   '1',   {:line => 1, :pos=>8, :length=>1 }],
                      [:RBRACK,   ']',   {:line => 1, :pos=>9, :length=>1 }],
                      [:DQPOST,   '',    {:line => 1, :pos=>11, :length=>1 }]],

    '"a${_x.foo}"'=> [[:DQPRE,    'a',   {:line => 1, :pos=>1, :length=>4 }],
                      [:VARIABLE, '_x',  {:line => 1, :pos=>5, :length=>2 }],
                      [:DOT,      '.',   {:line => 1, :pos=>7, :length=>1 }],
                      [:NAME,     'foo', {:line => 1, :pos=>8, :length=>3 }],
                      [:DQPOST,   '',    {:line => 1, :pos=>12, :length=>1 }]],
  }.each do |source, expected|
    it "should lex an interpolated variable 'x' from #{source}" do
      expect(tokens_scanned_from(source)).to match_tokens2(*expected)
    end
  end

  { '"$"'      => '$',
    '"a$"'     => 'a$',
    '"a$%b"'  => "a$%b",
    '"a$$"'  => "a$$",
    '"a$$%"'  => "a$$%",
  }.each do |source, expected|
    it "should lex interpolation including false starts #{source}" do
      expect(tokens_scanned_from(source)).to match_tokens2([:STRING, expected])
    end
  end

  it "differentiates between foo[x] and foo [x] (whitespace)" do
    expect(tokens_scanned_from("$a[1]")).to match_tokens2(:VARIABLE, :LBRACK, :NUMBER, :RBRACK)
    expect(tokens_scanned_from("$a [1]")).to match_tokens2(:VARIABLE, :LISTSTART, :NUMBER, :RBRACK)
    expect(tokens_scanned_from("a[1]")).to match_tokens2(:NAME, :LBRACK, :NUMBER, :RBRACK)
    expect(tokens_scanned_from("a [1]")).to match_tokens2(:NAME, :LISTSTART, :NUMBER, :RBRACK)
    expect(tokens_scanned_from(" if \n\r\t\nif if ")).to match_tokens2(:IF, :IF, :IF)
  end

  it "skips whitepsace" do
    expect(tokens_scanned_from(" if if if ")).to match_tokens2(:IF, :IF, :IF)
    expect(tokens_scanned_from(" if \n\r\t\nif if ")).to match_tokens2(:IF, :IF, :IF)
  end

  it "skips single line comments" do
    expect(tokens_scanned_from("if # comment\nif")).to match_tokens2(:IF, :IF)
  end

  ["if /* comment */\nif",
    "if /* comment\n */\nif",
    "if /*\n comment\n */\nif",
    ].each do |source|
    it "skips multi line comments" do
      expect(tokens_scanned_from(source)).to match_tokens2(:IF, :IF)
    end
  end

  { "=~" => [:MATCH, "=~ /./"],
    "!~" => [:NOMATCH, "!~ /./"],
    ","  => [:COMMA, ", /./"],
    "("  => [:LPAREN, "( /./"],
    "["  => [:LISTSTART, "[ /./"],
    "["  => [[:NAME, :LBRACK], "a[ /./"],
    "["  => [[:NAME, :LISTSTART], "a [ /./"],
    "{"  => [:LBRACE, "{ /./"],
    "+"  => [:PLUS, "+ /./"],
    "-"  => [:MINUS, "- /./"],
    "*"  => [:TIMES, "* /./"],
    ";"  => [:SEMIC, "; /./"],
  }.each do |token, entry|
    it "should lex regexp after '#{token}'" do
      expected = [entry[0], :REGEX].flatten
      expect(tokens_scanned_from(entry[1])).to match_tokens2(*expected)
    end
  end

  it "should lex a simple expression" do
    expect(tokens_scanned_from('1 + 1')).to match_tokens2([:NUMBER, '1'], :PLUS, [:NUMBER, '1'])
  end

  { "1"     => ["1 /./",       [:NUMBER, :DIV, :DOT, :DIV]],
    "'a'"   => ["'a' /./",     [:STRING, :DIV, :DOT, :DIV]],
    "true"  => ["true /./",    [:BOOLEAN, :DIV, :DOT, :DIV]],
    "false" => ["false /./",   [:BOOLEAN, :DIV, :DOT, :DIV]],
    "/./"   => ["/./ /./",     [:REGEX, :DIV, :DOT, :DIV]],
    "a"     => ["a /./",       [:NAME, :DIV, :DOT, :DIV]],
    "A"     => ["A /./",       [:CLASSREF, :DIV, :DOT, :DIV]],
    ")"     => [") /./",       [:RPAREN, :DIV, :DOT, :DIV]],
    "]"     => ["] /./",       [:RBRACK, :DIV, :DOT, :DIV]],
    "|>"     => ["|> /./",     [:RCOLLECT, :DIV, :DOT, :DIV]],
    "|>>"    => ["|>> /./",    [:RRCOLLECT, :DIV, :DOT, :DIV]],
    "$x"     => ["$x /1/",     [:VARIABLE, :DIV, :NUMBER, :DIV]],
    "a-b"    => ["a-b /1/",    [:WORD, :DIV, :NUMBER, :DIV]],
    '"a$a"'  => ['"a$a" /./',  [:DQPRE, :VARIABLE, :DQPOST, :DIV, :DOT, :DIV]],
  }.each do |token, entry|
    it "should not lex regexp after '#{token}'" do
      expect(tokens_scanned_from(entry[ 0 ])).to match_tokens2(*entry[ 1 ])
    end
  end

  it 'should lex assignment' do
    expect(tokens_scanned_from("$a = 10")).to match_tokens2([:VARIABLE, "a"], :EQUALS, [:NUMBER, '10'])
  end

# TODO: Tricky, and heredoc not supported yet
#  it "should not lex regexp after heredoc" do
#    tokens_scanned_from("1 / /./").should match_tokens2(:NUMBER, :DIV, :REGEX)
#  end

  it "should lex regexp at beginning of input" do
    expect(tokens_scanned_from(" /./")).to match_tokens2(:REGEX)
  end

  it "should lex regexp right of div" do
    expect(tokens_scanned_from("1 / /./")).to match_tokens2(:NUMBER, :DIV, :REGEX)
  end

  context 'when lexer lexes heredoc' do
    it 'lexes tag, syntax and escapes, margin and right trim' do
      code = <<-CODE
      @(END:syntax/t)
      Tex\\tt\\n
      |- END
      CODE
      expect(tokens_scanned_from(code)).to match_tokens2([:HEREDOC, 'syntax'], :SUBLOCATE, [:STRING, "Tex\tt\\n"])
    end

    it 'lexes "tag", syntax and escapes, margin, right trim and interpolation' do
      code = <<-CODE
      @("END":syntax/t)
      Tex\\tt\\n$var After
      |- END
      CODE
      expect(tokens_scanned_from(code)).to match_tokens2(
        [:HEREDOC, 'syntax'],
        :SUBLOCATE,
        [:DQPRE, "Tex\tt\\n"],
        [:VARIABLE, "var"],
        [:DQPOST, " After"]
        )
    end

    context 'with bad syntax' do
      def expect_issue(code, issue)
        expect { tokens_scanned_from(code) }.to raise_error(Puppet::ParseErrorWithIssue) { |e|
          expect(e.issue_code).to be(issue.issue_code)
        }
      end

      it 'detects and reports HEREDOC_UNCLOSED_PARENTHESIS' do
        code = <<-CODE
        @(END:syntax/t
        Text
        |- END
        CODE
        expect_issue(code, Puppet::Pops::Issues::HEREDOC_UNCLOSED_PARENTHESIS)
      end

      it 'detects and reports HEREDOC_WITHOUT_END_TAGGED_LINE' do
        code = <<-CODE
        @(END:syntax/t)
        Text
        CODE
        expect_issue(code, Puppet::Pops::Issues::HEREDOC_WITHOUT_END_TAGGED_LINE)
      end

      it 'detects and reports HEREDOC_INVALID_ESCAPE' do
        code = <<-CODE
        @(END:syntax/x)
        Text
        |- END
        CODE
        expect_issue(code, Puppet::Pops::Issues::HEREDOC_INVALID_ESCAPE)
      end

      it 'detects and reports HEREDOC_INVALID_SYNTAX' do
        code = <<-CODE
        @(END:syntax/t/p)
        Text
        |- END
        CODE
        expect_issue(code, Puppet::Pops::Issues::HEREDOC_INVALID_SYNTAX)
      end

      it 'detects and reports HEREDOC_WITHOUT_TEXT' do
        code = '@(END:syntax/t)'
        expect_issue(code, Puppet::Pops::Issues::HEREDOC_WITHOUT_TEXT)
      end

      it 'detects and reports HEREDOC_MULTIPLE_AT_ESCAPES' do
        code = <<-CODE
        @(END:syntax/tst)
        Tex\\tt\\n
        |- END
        CODE
        expect_issue(code, Puppet::Pops::Issues::HEREDOC_MULTIPLE_AT_ESCAPES)
      end
    end
  end

  context 'when dealing with multi byte characters' do
    it 'should support unicode characters' do
      code = <<-CODE
      "x\\u2713y"
      CODE
      # >= Ruby 1.9.3 reports \u
       expect(tokens_scanned_from(code)).to match_tokens2([:STRING, "x\u2713y"])
    end
    it 'should support unicode characters in long form' do
      code = <<-CODE
      "x\\u{1f452}y"
      CODE
      expect(tokens_scanned_from(code)).to match_tokens2([:STRING, "x\u{1f452}y"])
    end

    it 'should not select LISTSTART token when preceded by multibyte chars' do
      # This test is sensitive to the number of multibyte characters and position of the expressions
      # within the string - it is designed to fail if the position is calculated on the byte offset of the '['
      # instead of the char offset.
      #
      code = "$a = '\u00f6\u00fc\u00fc\u00fc\u00fc\u00e4\u00e4\u00f6\u00e4'\nnotify {'x': message => B['dkda'] }\n"
      expect(tokens_scanned_from(code)).to match_tokens2(
        :VARIABLE, :EQUALS, :STRING,
        [:NAME, 'notify'], :LBRACE,
        [:STRING, 'x'], :COLON,
        :NAME, :FARROW, :CLASSREF, :LBRACK, :STRING, :RBRACK,
        :RBRACE)
    end
  end

  context 'when lexing epp' do
    it 'epp can contain just text' do
      code = <<-CODE
      This is just text
      CODE
      expect(epp_tokens_scanned_from(code)).to match_tokens2(:EPP_START, [:RENDER_STRING, "      This is just text\n"])
    end

    it 'epp can contain text with interpolated rendered expressions' do
      code = <<-CODE
      This is <%= $x %> just text
      CODE
      expect(epp_tokens_scanned_from(code)).to match_tokens2(
      :EPP_START,
      [:RENDER_STRING, "      This is "],
      [:RENDER_EXPR, nil],
      [:VARIABLE, "x"],
      [:EPP_END, "%>"],
      [:RENDER_STRING, " just text\n"]
      )
    end

    it 'epp can contain text with trimmed interpolated rendered expressions' do
      code = <<-CODE
      This is <%= $x -%> just text
      CODE
      expect(epp_tokens_scanned_from(code)).to match_tokens2(
      :EPP_START,
      [:RENDER_STRING, "      This is "],
      [:RENDER_EXPR, nil],
      [:VARIABLE, "x"],
      [:EPP_END_TRIM, "-%>"],
      [:RENDER_STRING, "just text\n"]
      )
    end

    it 'epp can contain text with expressions that are not rendered' do
      code = <<-CODE
      This is <% $x=10 %> just text
      CODE
      expect(epp_tokens_scanned_from(code)).to match_tokens2(
      :EPP_START,
      [:RENDER_STRING, "      This is "],
      [:VARIABLE, "x"],
      :EQUALS,
      [:NUMBER, "10"],
      [:RENDER_STRING, " just text\n"]
      )
    end

    it 'epp can skip leading space in tail text' do
      code = <<-CODE
      This is <% $x=10 -%>
      just text
      CODE
      expect(epp_tokens_scanned_from(code)).to match_tokens2(
      :EPP_START,
      [:RENDER_STRING, "      This is "],
      [:VARIABLE, "x"],
      :EQUALS,
      [:NUMBER, "10"],
      [:RENDER_STRING, "just text\n"]
      )
    end

    it 'epp can skip comments' do
      code = <<-CODE
      This is <% $x=10 -%>
      <%# This is an epp comment -%>
      just text
      CODE
      expect(epp_tokens_scanned_from(code)).to match_tokens2(
      :EPP_START,
      [:RENDER_STRING, "      This is "],
      [:VARIABLE, "x"],
      :EQUALS,
      [:NUMBER, "10"],
      [:RENDER_STRING, "just text\n"]
      )
    end

    it 'epp can escape epp tags' do
      code = <<-CODE
      This is <% $x=10 -%>
      <%% this is escaped epp %%>
      CODE
      expect(epp_tokens_scanned_from(code)).to match_tokens2(
      :EPP_START,
      [:RENDER_STRING, "      This is "],
      [:VARIABLE, "x"],
      :EQUALS,
      [:NUMBER, "10"],
      [:RENDER_STRING, "<% this is escaped epp %>\n"]
      )
    end

    context 'with bad epp syntax' do
      def expect_issue(code, issue)
        expect { epp_tokens_scanned_from(code) }.to raise_error(Puppet::ParseErrorWithIssue) { |e|
          expect(e.issue_code).to be(issue.issue_code)
        }
      end

      it 'detects and reports EPP_UNBALANCED_TAG' do
        expect_issue('<% asf', Puppet::Pops::Issues::EPP_UNBALANCED_TAG)
      end

      it 'detects and reports EPP_UNBALANCED_COMMENT' do
        expect_issue('<%# asf', Puppet::Pops::Issues::EPP_UNBALANCED_COMMENT)
      end

      it 'detects and reports EPP_UNBALANCED_EXPRESSION' do
        expect_issue('asf <%', Puppet::Pops::Issues::EPP_UNBALANCED_EXPRESSION)
      end
    end
  end

  context 'when parsing bad code' do
    def expect_issue(code, issue)
      expect { tokens_scanned_from(code) }.to raise_error(Puppet::ParseErrorWithIssue) do |e|
        expect(e.issue_code).to be(issue.issue_code)
      end
    end

    it 'detects and reports issue ILLEGAL_CLASS_REFERENCE' do
      expect_issue('A::3', Puppet::Pops::Issues::ILLEGAL_CLASS_REFERENCE)
    end

    it 'detects and reports issue ILLEGAL_FULLY_QUALIFIED_CLASS_REFERENCE' do
      expect_issue('::A::3', Puppet::Pops::Issues::ILLEGAL_FULLY_QUALIFIED_CLASS_REFERENCE)
    end

    it 'detects and reports issue ILLEGAL_FULLY_QUALIFIED_NAME' do
      expect_issue('::a::3', Puppet::Pops::Issues::ILLEGAL_FULLY_QUALIFIED_NAME)
    end

    it 'detects and reports issue ILLEGAL_NUMBER' do
     expect_issue('3g', Puppet::Pops::Issues::ILLEGAL_NUMBER)
    end

    it 'detects and reports issue INVALID_HEX_NUMBER' do
      expect_issue('0x3g', Puppet::Pops::Issues::INVALID_HEX_NUMBER)
    end

    it 'detects and reports issue INVALID_OCTAL_NUMBER' do
      expect_issue('038', Puppet::Pops::Issues::INVALID_OCTAL_NUMBER)
    end

    it 'detects and reports issue INVALID_DECIMAL_NUMBER' do
      expect_issue('4.3g', Puppet::Pops::Issues::INVALID_DECIMAL_NUMBER)
    end

    it 'detects and reports issue NO_INPUT_TO_LEXER' do
      expect { Puppet::Pops::Parser::Lexer2.new.fullscan }.to raise_error(Puppet::ParseErrorWithIssue) { |e|
        expect(e.issue_code).to be(Puppet::Pops::Issues::NO_INPUT_TO_LEXER.issue_code)
      }
    end

    it 'detects and reports issue UNCLOSED_QUOTE' do
      expect_issue('"asd', Puppet::Pops::Issues::UNCLOSED_QUOTE)
    end
  end
end
