module Cucumber
    module Tasks
        # Task used to monitor if an event happens within a certain time
        class JobEmitsEvent < Roby::Task
            # You usually want this
            terminates

            # The job ID of the job we're monitoring
            argument :monitored_job_id
            # The name of the event
            argument :event_name
            # How long we should wait for the event (in seconds)
            argument :timeout

            # The task being monitored
            attr_reader :job_task

            event :timeout
            forward :timeout => :failed

            event :start do |context|
                job = plan.find_tasks(Roby::Interface::Job).
                    with_arguments(job_id: monitored_job_id).first
                if !job
                    raise ArgumentError, "no job with ID #{monitored_job_id}"
                end
                @job_task = job.planned_task
                start_event.emit

                generator = job_task.event(event_name)
                if generator.emitted?
                    success_event.emit
                else
                    generator.forward_to success_event
                    depends_on job_task, success: event_name
                end
            end

            poll do
                if lifetime > timeout
                    timeout_event.emit
                end
            end
        end
    end
end
