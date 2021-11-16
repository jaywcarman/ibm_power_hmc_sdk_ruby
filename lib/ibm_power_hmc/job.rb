# frozen_string_literal: true

module IbmPowerHmc
  ##
  # HMC Job for long running operations.
  class HmcJob
    class JobNotStarted < StandardError; end

    ##
    # @!method initialize(conn, method_url, operation, group, params = {})
    # Construct a new HMC Job.
    #
    # @param conn [IbmPowerHmc::Connection] The connection to the HMC.
    # @param method_url [String] The method URL.
    # @param operation [String] The name of the requested operation.
    # @param group [String] The name of the group.
    # @param params [Hash] The job name/value parameters.
    def initialize(conn, method_url, operation, group, params = {})
      @conn = conn
      @method_url = method_url
      @operation = operation
      @group = group
      @params = params
    end

    ##
    # @!method start
    # Start the job asynchronously.
    # @return [String] The ID of the job.
    def start
      headers = {
        :content_type => "application/vnd.ibm.powervm.web+xml; type=JobRequest"
      }
      doc = REXML::Document.new("")
      doc.add_element("JobRequest:JobRequest", "schemaVersion" => "V1_1_0")
      doc.root.add_namespace("http://www.ibm.com/xmlns/systems/power/firmware/web/mc/2012_10/")
      doc.root.add_namespace("JobRequest", "http://www.ibm.com/xmlns/systems/power/firmware/web/mc/2012_10/")
      op = doc.root.add_element("RequestedOperation", "schemaVersion" => "V1_1_0")
      op.add_element("OperationName").text = @operation
      op.add_element("GroupName").text = @group

      jobparams = doc.root.add_element("JobParameters", "schemaVersion" => "V1_1_0")
      @params.each do |key, value|
        jobparam = jobparams.add_element("JobParameter", "schemaVersion" => "V1_1_0")
        jobparam.add_element("ParameterName").text = key
        jobparam.add_element("ParameterValue").text = value
      end
      response = @conn.request(:put, @method_url, headers, doc.to_s)
      jobresp = Parser.new(response.body).object(:JobResponse)
      @id = jobresp.id
    end

    # @return [Hash] The job results returned by the HMC.
    attr_reader :results

    ##
    # @!method status
    # Return the status of the job.
    # @return [String] The status of the job.
    def status
      raise JobNotStarted unless defined?(@id)

      method_url = "/rest/api/uom/jobs/#{@id}"
      headers = {
        :content_type => "application/vnd.ibm.powervm.web+xml; type=JobRequest"
      }
      response = @conn.request(:get, method_url, headers)
      jobresp = Parser.new(response.body).object(:JobResponse)
      @results = jobresp.results
      jobresp.status
    end

    ##
    # @!method wait(timeout = 120, poll_interval = 0)
    # Wait for the job to complete.
    # @param timeout [Integer] The maximum time in seconds to wait for the job to complete.
    # @param poll_interval [Integer] The interval in seconds between status queries (0 means auto).
    # @return [String] The status of the job.
    def wait(timeout = 120, poll_interval = 0)
      endtime = Time.now.utc + timeout
      auto = poll_interval == 0
      poll_interval = 1 if auto
      while Time.now.utc < endtime
        status = self.status
        return status if status != "RUNNING" && status != "NOT_STARTED"

        poll_interval *= 2 if auto && poll_interval < 30
        sleep(poll_interval)
      end
      "TIMEDOUT"
    end

    ##
    # @!method run(timeout = 120, poll_interval = 0)
    # Run the job synchronously.
    # @param timeout [Integer] The maximum time in seconds to wait for the job to complete.
    # @param poll_interval [Integer] The interval in seconds between status queries (0 means auto).
    # @return [String] The status of the job.
    def run(timeout = 120, poll_interval = 0)
      start
      wait(timeout, poll_interval)
    ensure
      delete if defined?(@id)
    end

    ##
    # @!method delete
    # Delete the job from the HMC.
    def delete
      raise JobNotStarted unless defined?(@id)

      # HMC bug: cannot delete Partition Template capture jobs
      unless @operation.eql?("Capture") && @group.eql?("PartitionTemplate")
        method_url = "/rest/api/uom/jobs/#{@id}"
        @conn.request(:delete, method_url)
        # Returns HTTP 204 if ok
      end
    end
  end
end
