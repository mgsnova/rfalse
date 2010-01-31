# RFalse is a FALSE Interpreter written in Ruby
#
# FALSE is an esoteric programming language designed
# with the goal of "confusing everyone with an
# obfuscated syntax" - so dont blame me :-)
#
# For further information about FALSE take a look there:
#   http://strlen.com/false/
#   http://en.wikipedia.org/wiki/FALSE
#
# Use the Ruby Interpreter like this:
#
# ruby rfalse.rb greatcode.f
# ruby rfalse.rb < greatcode.f
#
# rfalse will read its code to interpret either from
# the given filename or from stdin. Parameter -v will
# enable verbose mode, which shows the the stack and
# the execution pointer at each step
#
# BUGS:
#  - not all examples given, are working
#  - not all language functionality implemented
#
# TODO:
#  - redesign this thing
#  - clear division of code into tokenizer, parser, interpreter and runtime
#  - more tests


require 'pp'
require 'rubygems'
require 'highline/import'

# little String patch
String.class_eval do
  def at(q); self[q,1]; end
end

# RStack provides the behaviour of a stack and
# comes with the functionality needed for
# implementing a FALSE interpreter
#
class RStack < Array

  # return top object from stack without removing it
  #
  def top
    self[-1]
  end

  # print the stack
  #
  def show
    if size > 0
      puts "____________"
      puts "-> #{self[-1]}\n"
      (size - 1).downto(1) do |c|
        puts "   #{self[c]}\n"
      end
      puts "____________\n\n"
    else
      puts "empty stack"
    end
  end

  # pop the 2 top elements of the stack,
  # add them and push back to stack
  #
  def +
    push pop + pop
  end

  # pop the 2 top elements of the stack,
  # subtract from another and push
  # result back to stack
  #
  def -
    a = pop
    b = pop
    push b - a
  end

  # pop the 2 top elements of the stack
  # and push back the result of the multiply
  #
  def *
    push pop * pop
  end

  # pop the 2 top elements of the stack
  # and push back the result of the division
  #
  def /
    a = pop
    b = pop
    push b / a
  end

  # negate the top element of the stack
  #
  def _
    push -pop
  end

  # pop the 2 top elements of the stack,
  # compare them on equality and push result back
  # true  = -1
  # false = 0
  #
  def eq #=
    push pop == pop ? -1 : 0
  end

  # pop the 2 top elements of the stack,
  # compare them on first bigger than second
  # and push result back
  # true  = -1
  # false = 0
  #
  def >
    a = pop
    b = pop
    push b > a ? -1 : 0
  end

  # Perform an NOT ont the top element on stack
  # error will be raised if not boolean
  #
  def ~
    case pop
      when 0
        push -1
      when -1
        push 0
      else
        raise StandardError, "expecting bool"
    end
  end

  # Perform an AND on the 2 top elements on stack,
  # pushing back -1 if true or 0 if false
  #
  def &
    a = pop
    b = pop
    push (a == -1) && (b == -1) ? -1 : 0
  end

  # Perform an OR on the 2 top elements on stack,
  # pushing back -1 if true or 0 if false
  #
  def |
    a = pop
    b = pop
    push (a == -1) || (b == -1) ? -1 : 0
  end

  # Duplicate top element on stack
  #
  def dup #$
    a = pop
    push a
    push a
  end

  # Remove top element from stack
  def %
    pop
  end

  # Swap the 2 top elements on the stack
  def swap #\
    a = pop
    b = pop
    push a
    push b
  end

  # Rotate the 3 top elements on the stack
  #
  def rot #@
    a = pop
    b = pop
    c = pop
    push a
    push c
    push b
  end

  # Copy the n'th element of the stack to top
  # n is the value of the first element on stack
  #
  def pick #ø
    a = pop
    raise StandardError, "stack is not that big" if size <= a
    b = self[-a]
    push a
    push b
  end

end

# Main Class of FALSE Ruby Interpreter
#
# Just create new instance and run obj.run('your FALSE code')
#
class RFalse
  def initialize
    @stack = RStack.new
    @while_stack = RStack.new
    @global_variables = {}
    @str_p = 0
  end

  # run the interpreter with the given code
  # optional verbose mode
  #
  def run(code, verbose = false)

    # loop over the code until end is reached
    #
    while(@str_p < code.size)
      puts code[@str_p,code.size-@str_p] if verbose

      # decide what shall be done now
      #
      case code[@str_p,1]

        # ignore this characters
        when " ","\r","\t","\n"

        # perform addition on stack
        when "+"
          @stack.+

        # perform substraction on stack
        when "-"
          @stack.-

        # perform multiplication on stack
        when "*"
          @stack.*

        # perform division on stack
        when "/"
          @stack./

        # perform negation on stack
        when "_"
          @stack._

        # perform equality check on stack
        when "="
          @stack.eq

        # perform greater than check on stack
        when ">"
          @stack.>

        # perform NOT on stack
        when "~"
          @stack.~

        # perform AND on stack
        when "&"
          @stack.&

        # perform OR on stack
        when "|"
          @stack.|

        # Duplicate top element on stack
        when "$"
          @stack.dup

        # Remove top element on stack
        when "%"
          @stack.%

        # Perform swapping on 2 top elements
        when "\\"
          @stack.swap

        # Perform rotation on 3 top elements
        when "@"
          @stack.rot

        # Copy nth element to the top of stack
        when "ø"
          @stack.pick

        # handle comments
        when "{"
          @str_p = code.index('}', @str_p + 1)

        # Push the integer on stack
        when '0','1','2','3','4','5','6','7','8','9'
         num = code[@str_p..code.size].match /\A\d+/ 
         @stack.push num[0].to_i
         @str_p += (num[0].size - 1)

        # read lambda function and push on stack
        when "["
          f = 1
          c = 1
          while f > 0 do
            f += 1 if code.at(@str_p + c) == '['
            f -= 1 if code.at(@str_p + c) == ']'
            c += 1
          end
          @stack.push l = code[@str_p + 1 ..  @str_p + c - 2]
          @str_p += l.size + 1

        # Print text between the "
        when '"'
          c = code[@str_p + 1 ..  code.index('"', @str_p + 1) - 1]
          @str_p += c.size+1
          puts c

        # Perform accessing on global variables a-z, : is value assignment, ; pushes value on stack
        when 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z' #assing or push global variables
          if code.at(@str_p + 1) == ':'
            @global_variables[code.at(@str_p)] = @stack.pop
            @str_p += 1
          elsif code[@str_p + 1, 1] == ';'
            @stack.push @global_variables[code.at(@str_p)] or raise StandardError, "Undefined global variable"
            @str_p += 1
          else
            raise StandardError, "Syntax error with global variables"
          end

        # Execute the lambda function on stack (means copying it to after the !)
        when '!'
          code.insert(@str_p + 1, @stack.pop)

        # Print top element as integer
        when '.'
          puts @stack.pop.to_i

        # Print top element as character
        when ','
          puts @stack.pop.chr

        # Read one single character from stdin and push to stack
        when '^'
          c = nil
          while (c = ask('') { |q| q.character = true; q.echo = false }) != "\e" do
            break
          end
          @stack.push c.to_i.to_s == c ? c.to_i : c

        # Push the Character after \ as integer on stack
        when '\''
          c = code.at(@str_p + 1)
          @stack.push c.to_i.to_s == c ? c.to_i : c
          @str_p += 1

        # Flush input and output
        when 'ß'
          STDOUT.flush

        # Perform an IF
        when '?'
          f = @stack.pop
          b = @stack.pop
          code = code.insert(@str_p + 1, f) if b == -1

        # Perform a WHILE
        when "#"
          a = @stack.pop
          b = @stack.pop
          @while_stack.push b
          @while_stack.push a
          code = code.insert(@str_p + 1, "[#{b}]!W")

        # Helper for WHILE
        when "W"
          r = @stack.pop
          a = @while_stack.pop
          b = @while_stack.pop
          if r == -1
            @while_stack.push b
            @while_stack.push a
            code = code.insert(@str_p + 1, "[#{a}]![#{b}]!W")
          end

        else
          raise StandardError, "syntax error"
      end

      @stack.show if verbose

      # in next step go for the next character
      @str_p += 1
    end
  end
end

# raise if there to much arguments
raise StandardError, "Too many arguments" if ARGV.size > 2

# read the code to interpret from file or stdin
data = if (ARGV-['-v']).size == 1
  File.open((ARGV - ['-v']).first).read
else
  STDIN.read
end

# lets interpret the code
rf = RFalse.new
rf.run(data, ARGV.include?('-v'))

#rf.run('[$1=$[\%1\]?~[$1-f;!*]?]f:6f;!.', ARGV.include?('-v'))
#rf.run('1a:[5a;=~][a;.1a;+a:]#', ARGV.include?('-v'))
#rf.run("99 9[1-$][\$@$@$@$@\/*=[1-$$[%\\1-$@]?0=[\$.' ,\]?]?]#", ARGV.include?('-v'))
