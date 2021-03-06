# Represents an Awesome object instance in the Ruby world.
class AwesomeObject
  attr_accessor :awesome_class, :ruby_value
  
  # Each object have a class (named awesome_class to prevent errors with Ruby's class
  # method). Optionaly an object can hold a Ruby value (eg.: numbers and strings).
  def initialize(awesome_class, ruby_value=self)
    @awesome_class = awesome_class
    @ruby_value = ruby_value
  end
  
  # Call a method on the object.
  def call(method, arguments)
    # Like a typical Class-based runtime model, we store methods in the class of the
    # object.
    @awesome_class.lookup(method).call(self, arguments)
  end
end

# Represents a Awesome class in the Ruby world. Classes are objects in Awesome so they
# inherit from AwesomeObject.
class AwesomeClass < AwesomeObject
  attr_reader :awesome_methods
  
  # Creates a new class. Number is an instance of Class for example.
  def initialize
    @awesome_methods = {}
    
    # Check if we're bootstrapping (launching the runtime). During this process the 
    # runtime is not fully initialized and core classes do not yet exists, so we defer 
    # using those once the language is bootstrapped.
    # This solves the chicken-or-the-egg problem with the Class class. We can 
    # initialize Class then set Class.class = Class.
    if defined?(Runtime)
      awesome_class = Runtime["Class"]
    else
      awesome_class = nil
    end
    
    super(awesome_class)
  end
  
  # Lookup a method
  def lookup(method_name)
    method = @awesome_methods[method_name]
    unless method
      raise "Method not found: #{method_name}"
    end
    method
  end
  
  # Create a new instance of this Awesome class
  def new
    AwesomeObject.new(self)
  end
  
  # Create an instance of this Awesome class that holds a Ruby value. Like a String, 
  # Number or true.
  def new_value(value)
    AwesomeObject.new(self, value)
  end
end

# Represents a method defined in the Awesome world. We can use Ruby's Proc to define a 
# method in Ruby world. You'll see more about defining awesome methods in Ruby at the 
# end of this file, during the bootstrapping process.
class AwesomeMethod
  def initialize(params, body)
    @params = params
    @body = body
  end
  
  def call(receiver, arguments)
    @body.eval(Context.new(receiver))
  end
end

# Represents the evaluation context, that tracks values that change depending on where 
# the code is evaluated.
# - "locals" holds local variables.
# - "current_self" is the object on which methods with no receivers are called,
#   eg.: print is like current_self.print
# - "current_class" is the class on which methods are defined with the "def" keyword.
class Context
  attr_reader :locals, :current_self, :current_class
  
  # We store constants as class variable (class variables start with @@ and instance
  # variables start with @ in Ruby) since they are globally accessible. If you want to
  # implement namespacing of constants, you could store it in the instance of this 
  # class.
  @@constants = {}
  
  def initialize(current_self, current_class=current_self.awesome_class)
    @locals = {}
    @current_self = current_self
    @current_class = current_class
  end
  
  # Shortcuts to access constants, Runtime[...] instead of Runtime.constants[...]
  def [](name)
    @@constants[name]
  end
  def []=(name, value)
    @@constants[name] = value
  end
end

# Bootstrap the runtime. This is where we assemble all the classes and objects together
# to form the runtime.
awesome_class = AwesomeClass.new            # Class is a class
awesome_class.awesome_class = awesome_class # Class.class == Class
awesome_object_class = AwesomeClass.new     # Object = Class.new

# Create the Runtime object (the root context) on which all code will start its
# evaluation.
Runtime = Context.new(awesome_object_class.new)

# Register the core classes as constants in the runtime so we can access them from 
# within a program.
Runtime["Class"] = awesome_class
Runtime["Object"] = awesome_object_class
Runtime["Number"] = AwesomeClass.new
Runtime["String"] = AwesomeClass.new
Runtime["TrueClass"] = AwesomeClass.new
Runtime["FalseClass"] = AwesomeClass.new
Runtime["NilClass"] = AwesomeClass.new

# Register primitives that map to Ruby values
Runtime["true"] = Runtime["TrueClass"].new_value(true)
Runtime["false"] = Runtime["FalseClass"].new_value(false)
Runtime["nil"] = Runtime["NilClass"].new_value(nil)

# Define some Awesome methods in Ruby. We can use a proc since they respond to "call".
Runtime["Class"].awesome_methods["new"] = proc do |receiver, arguments|
  # Creates a new instance of the class
  receiver.new
end
Runtime["Object"].awesome_methods["print"] = proc do |receiver, arguments|
  puts arguments.first.ruby_value
  Runtime["nil"] # Return value for Awesome
end
