# encoding: utf-8
require 'optparse'
require 'racker/processor'
require 'racker/version'

module Racker
  # The CLI is a class responsible for handling the command line interface
  # logic.
  class CLI
    include Racker::LogSupport

    attr_reader :options

    def initialize(argv)
      @argv = argv
    end

    def execute!
      # Parse our arguments
      option_parser.parse!(@argv)

      # Set the logging level specified by the command line
      Racker::LogSupport.level = options[:log_level]

      # Display the options if a minimum of 1 template and an output file is not provided
      if @argv.length < 2
        puts option_parser
        Kernel.exit!(1)
      end

      # Set the output file to the last arg
      options[:output] = @argv.pop
      logger.debug("Output file set to: #{options[:output]}")

      # Set the input files to the remaining args
      options[:templates] = @argv

      options[:quiet] = true if options[:output] == '-'
      # Run through Racker
      logger.debug('Executing the Racker Processor...')
      template = Processor.new(options).execute!

      write(@options[:output], template)

      # Thats all folks!
      logger.debug('Processing complete.')
      puts "Processing complete!" unless options[:quiet]
      puts "Packer file generated: #{options[:output]}" unless options[:quiet]

      return 0
    end

    private

    def options
      @options ||= {
        log_level:     :warn,
        knockout:      '~~',
        output:        '',
        templates:     [],
        quiet:         false,
      }
    end

    def option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: #{opts.program_name} [options] [TEMPLATE1, TEMPLATE2, ...] OUTPUT"

        opts.on('-l', '--log-level [LEVEL]', [:fatal, :error, :warn, :info, :debug], 'Set log level') do |v|
          options[:log_level] = v
        end

        opts.on('-k', '--knockout PREFIX', 'Set the knockout prefix (Default: ~~)') do |v|
          options[:knockout] = v || '~~'
        end

        opts.on('-q', '--quiet', 'Disable unnecessary output') do |v|
          options[:quiet] = true
        end

        opts.on_tail('-h', '--help', 'Show this message') do
          puts option_parser
          Kernel.exit!(0)
        end

        opts.on_tail('-v', '--version', "Show #{opts.program_name} version") do
          puts Racker::Version.version
          Kernel.exit!(0)
        end
      end
    end

    def write(output_path, template)
      if output_path == '-'
        write_to_stdout(template)
      else
        write_to_file(@options[:output], template)
      end
    end

    def write_to_file(path, template)
      # Check that the output directory exists
      output_dir = File.dirname(File.expand_path(@options[:output]))

      # If the output directory doesnt exist
      logger.info('Creating the output directory if it does not exist...')
      FileUtils.mkdir_p output_dir unless File.exists? output_dir

      File.open(@options[:output], 'w') do |file|
        logger.info('Writing packer template...')
        file.write(template)
        logger.info('Writing packer template complete.')
      end
    end

    def write_to_stdout(template)
      $stdout.puts("#{template}\n")
      $stdout.flush
    end
  end
end
