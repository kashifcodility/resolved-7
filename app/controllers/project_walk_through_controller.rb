require 'sdn/cart'
class ProjectWalkThroughController < ApplicationController
    protect_from_forgery with: :null_session
  
    def step1
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step1)
            @id = params[:id]
        end    
    end

    def create_step1
        errors = []
        file_url = ''

        if params[:img]
            errors << 'Photo too large. Max size is 4 MB.' unless params[:img].size <= 4.megabyte
  
            unless errors.any?
                new_filename = "#{current_user.username}_#{Time.zone.now.to_i}_#{params[:img].original_filename}"
                s3_bucket = 'sdn-content'
  
                # Perform the upload
                upload_success = $AWS.s3.upload(
                    params[:img].tempfile,
                    bucket: s3_bucket,
                    as: new_filename,
                )
    
                if upload_success
                    # Generate the file URL
                    file_url = $AWS.s3.public_url_for(new_filename, bucket: s3_bucket)
                    # order_query.image_url = file_url
                else
                    errors << 'Error uploading photo.'
                end
  
                puts 'received your file. now move to the next step'
            end
        end

        project_walk_through = ProjectWalkThrough.find(params[:project_walk_through_id]) if params[:project_walk_through_id].present?
        project = project_walk_through || ProjectWalkThrough.new

        old_file_url = eval(project.step1)[:img] unless project.step1.nil?
        
        errors = []

        step1 = {
            order_no: params[:order_no], 
            budget: params[:budget], 
            design_style: params[:design_style],
            design_staging: params[:design_staging], 
            two: params[:two], 
            three: params[:three], 
            four: params[:four], 
            five: params[:five],
            start: params[:start], 
            end: params[:end], 
            job_name: params[:job_name],
            stage_date: params[:stage_date], 
            out_of_area: params[:out_of_area], 
            occupied: params[:occupied],
            access: params[:access], 
            needs: params[:needs], 
            img: file_url.present? ? file_url : old_file_url,
            furniture: params[:furniture], 
            budgeted_pull: params[:budgeted_pull], 
            actual_pull: params[:actual_pull],
            budgeted_stage: params[:budgeted_stage]
        }
        #   project = ProjectWalkThrough.new(step1: step1)
          project.order_id = params[:order_no].to_i  if params[:project_walk_through_id].blank?
          project.step1 = step1
        if project.save
            redirect_to "/project_walk_through/step2?id=#{project.id}"
        else
            render :step1    
        end           
    end  
    
    
    def step2
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step2) if project_walk_through.step2.present?
            @id = params[:id]
        end
    end

    def create_step2        
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step2)[:images] unless project.step2.nil?
        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end 

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step2 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                needs: params[:needs], 
                good: params[:good],
                drapes_length: params[:drapes_length], 
                console_small: params[:console_small], 
                console_medium: params[:console_medium],
                console_large: params[:console_large],
                cabinet_small: params[:cabinet_small],
                cabinet_medium: params[:cabinet_medium],
                cabinet_large: params[:cabinet_large],
                armchair_small: params[:armchair_small],
                armchair_medium: params[:armchair_medium],
                armchair_large: params[:armchair_large],
                side_small: params[:side_small],
                side_medium: params[:side_medium],
                side_large: params[:side_large],
                plant: params[:plant],
                tree: params[:tree],
                bench_small: params[:bench_small],
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],
                notes: params[:notes],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step2: step2)
               redirect_to "/project_walk_through/step3?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step2
               return
            end         
        else
            render :step2
            return
        end        
    end     

    def step3
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step3) if project_walk_through.step3.present?
            @id = params[:id]
        end
    end

    def create_step3
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step3)[:images] unless project.step3.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end  
        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  
            
            step3 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                needs: params[:needs], 
                good: params[:good],
                drapes_length: params[:drapes_length], 
                console_small: params[:console_small], 
                console_medium: params[:console_medium],
                console_large: params[:console_large],
                plant: params[:plant],
                tree: params[:tree],
                bookcase_small: params[:bookcase_small],
                bookcase_medium: params[:bookcase_medium],
                bookcase_large: params[:bookcase_large],
                media_small: params[:media_small],
                media_medium: params[:media_medium],
                media_large: params[:media_large],
                floor_lamp_small: params[:floor_lamp_small],
                floor_lamp_medium: params[:floor_lamp_medium],
                floor_lamp_large: params[:floor_lamp_large],
                game_table_small: params[:game_table_small],
                game_table_medium: params[:game_table_medium],
                game_table_large: params[:game_table_large],
                dining_chair_small: params[:dining_chair_small],
                dining_chair_medium: params[:dining_chair_medium],
                dining_chair_large: params[:dining_chair_large],
                tent_small: params[:tent_small],
                tent_medium: params[:tent_medium],
                tent_large: params[:tent_large],
                sofa_small: params[:sofa_small],
                sofa_medium: params[:sofa_medium],
                sofa_large: params[:sofa_large],
                love_seat_small: params[:love_seat_small], 
                love_seat_medium: params[:love_seat_medium],
                love_seat_large: params[:love_seat_large],
                sectional_small: params[:sectional_small], 
                sectional_medium: params[:sectional_medium],
                sectional_large: params[:sectional_large],
                bench_small: params[:bench_small], 
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],
                cofee_ottoman_small: params[:cofee_ottoman_small], 
                cofee_ottoman_medium: params[:cofee_ottoman_medium],
                cofee_ottoman_large: params[:cofee_ottoman_large],
                bench_small: params[:bench_small], 
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],
                side_table_small: params[:side_table_small], 
                side_table_medium: params[:side_table_medium],
                side_table_large: params[:side_table_large],
                chest_cabinet_small: params[:chest_cabinet_small], 
                chest_cabinet_medium: params[:chest_cabinet_medium],
                chest_cabinet_large: params[:chest_cabinet_large],
                cabinet_small: params[:cabinet_small],
                cabinet_medium: params[:cabinet_medium],
                cabinet_large: params[:cabinet_large],
                armchair_small: params[:armchair_small],
                armchair_medium: params[:armchair_medium],
                armchair_large: params[:armchair_large],
                side_small: params[:side_small],
                side_medium: params[:side_medium],
                side_large: params[:side_large],
                plant_tree_small: params[:plant_tree_small],
                plant_tree_medium: params[:plant_tree_medium],
                plant_tree_large: params[:plant_tree_large],
                bench_small: params[:bench_small],
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],
                notes: params[:notes],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step3: step3)
               redirect_to "/project_walk_through/step4?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step3
               return
            end         
        else
            render :step3
            return
        end        
    end

    def step4
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step4) if project_walk_through.step4.present?
            @id = params[:id]
        end
    end

    def create_step4
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step4)[:images] unless project.step4.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end  

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step4 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                needs: params[:needs], 
                good: params[:good],
                drapes_length: params[:drapes_length], 
                console_small: params[:console_small], 
                console_medium: params[:console_medium],
                console_large: params[:console_large],
                # plant_tree_small: params[:plant_tree_small],
                # plant_tree_medium: params[:plant_tree_medium],
                # plant_tree_large: params[:plant_tree_large],
                # bookcase_small: params[:bookcase_small],
                # bookcase_medium: params[:bookcase_medium],
                # bookcase_large: params[:bookcase_large],
                # media_small: params[:media_small],
                # media_medium: params[:media_medium],
                # media_large: params[:media_large],
                floor_lamp_small: params[:floor_lamp_small],
                floor_lamp_medium: params[:floor_lamp_medium],
                floor_lamp_large: params[:floor_lamp_large],
                # game_table_small: params[:game_table_small],
                # game_table_medium: params[:game_table_medium],
                # game_table_large: params[:game_table_large],
                # dining_chair_small: params[:dining_chair_small],
                # dining_chair_medium: params[:dining_chair_medium],
                # dining_chair_large: params[:dining_chair_large],
                # tent_small: params[:tent_small],
                # tent_medium: params[:tent_medium],
                # tent_large: params[:tent_large],
                # sofa_small: params[:sofa_small],
                # sofa_medium: params[:sofa_medium],
                # sofa_large: params[:sofa_large],
                # love_seat_small: params[:love_seat_small], 
                # love_seat_medium: params[:love_seat_medium],
                # love_seat_large: params[:love_seat_large],
                # sectional_small: params[:sectional_small], 
                # sectional_medium: params[:sectional_medium],
                # sectional_large: params[:sectional_large],
                bench_small: params[:bench_small], 
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],
                # cofee_ottoman_small: params[:cofee_ottoman_small], 
                # cofee_ottoman_medium: params[:cofee_ottoman_medium],
                # cofee_ottoman_large: params[:cofee_ottoman_large],
                chair_small: params[:chair_small], 
                chair_medium: params[:chair_medium],
                chair_large: params[:chair_large],
                table_small: params[:table_small], 
                table_medium: params[:table_medium],
                table_large: params[:table_large],
                # chest_cabinet_small: params[:chest_cabinet_small], 
                # chest_cabinet_medium: params[:chest_cabinet_medium],
                # chest_cabinet_large: params[:chest_cabinet_large],
                # cabinet_small: params[:cabinet_small],
                # cabinet_medium: params[:cabinet_medium],
                # cabinet_large: params[:cabinet_large],
                # armchair_small: params[:armchair_small],
                # armchair_medium: params[:armchair_medium],
                # armchair_large: params[:armchair_large],
                # side_small: params[:side_small],
                # side_medium: params[:side_medium],
                # side_large: params[:side_large],
                plant: params[:plant],
                tree: params[:tree],
                buffet_small: params[:buffet_small],
                buffet_medium: params[:buffet_medium],
                buffet_large: params[:buffet_large],
                notes: params[:notes],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step4: step4)
               redirect_to "/project_walk_through/step5?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step4
               return
            end         
        else
            render :step4
            return
        end        
    end

    def step5
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step5) if project_walk_through.step5.present?
            @id = params[:id]
        end
    end

    def create_step5
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step5)[:images] unless project.step5.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end 

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step5 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                needs: params[:needs], 
                good: params[:good],
                drapes_length: params[:drapes_length], 
                
                
                # bookcase_small: params[:bookcase_small],
                # bookcase_medium: params[:bookcase_medium],
                # bookcase_large: params[:bookcase_large],
                # media_small: params[:media_small],
                # media_medium: params[:media_medium],
                # media_large: params[:media_large],
               
                # game_table_small: params[:game_table_small],
                # game_table_medium: params[:game_table_medium],
                # game_table_large: params[:game_table_large],
                # dining_chair_small: params[:dining_chair_small],
                # dining_chair_medium: params[:dining_chair_medium],
                # dining_chair_large: params[:dining_chair_large],
                # tent_small: params[:tent_small],
                # tent_medium: params[:tent_medium],
                # tent_large: params[:tent_large],
                # sofa_small: params[:sofa_small],
                # sofa_medium: params[:sofa_medium],
                # sofa_large: params[:sofa_large],
                # love_seat_small: params[:love_seat_small], 
                # love_seat_medium: params[:love_seat_medium],
                # love_seat_large: params[:love_seat_large],
                # sectional_small: params[:sectional_small], 
                # sectional_medium: params[:sectional_medium],
                # sectional_large: params[:sectional_large],
                bar_stool_small: params[:bar_stool_small], 
                bar_stool_medium: params[:bar_stool_medium],
                bar_stool_large: params[:bar_stool_large],
                # cofee_ottoman_small: params[:cofee_ottoman_small], 
                # cofee_ottoman_medium: params[:cofee_ottoman_medium],
                # cofee_ottoman_large: params[:cofee_ottoman_large],
                
                # chest_cabinet_small: params[:chest_cabinet_small], 
                # chest_cabinet_medium: params[:chest_cabinet_medium],
                # chest_cabinet_large: params[:chest_cabinet_large],
                chair_small: params[:chair_small], 
                chair_medium: params[:chair_medium],
                chair_large: params[:chair_large],
                table_small: params[:table_small], 
                table_medium: params[:table_medium],
                table_large: params[:table_large],
                cabinet_small: params[:cabinet_small],
                cabinet_medium: params[:cabinet_medium],
                cabinet_large: params[:cabinet_large],
                console_small: params[:console_small], 
                console_medium: params[:console_medium],
                console_large: params[:console_large],
                plant: params[:plant],
                tree: params[:tree],
                bar_cart_small: params[:bar_cart_small],
                bar_cart_medium: params[:bar_cart_medium],
                bar_cart_large: params[:bar_cart_large],
                bar_stool_small: params[:bar_stool_small],
                bar_stool_medium: params[:bar_stool_medium],
                bar_stool_large: params[:bar_stool_large],
                # armchair_small: params[:armchair_small],
                # armchair_medium: params[:armchair_medium],
                # armchair_large: params[:armchair_large],
                # side_small: params[:side_small],
                # side_medium: params[:side_medium],
                # side_large: params[:side_large],
               
                counter_stool_small: params[:counter_stool_small],
                counter_stool_medium: params[:counter_stool_medium],
                counter_stool_large: params[:counter_stool_large],
                notes: params[:notes],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step5: step5)
               redirect_to "/project_walk_through/step6?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step5
               return
            end         
        else
            render :step5
            return
        end        
    end

    def step6
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step6) if project_walk_through.step6.present?
            @id = params[:id]
        end
    end

    def create_step6
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step6)[:images] unless project.step6.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end 

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step6 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                needs: params[:needs], 
                good: params[:good],
                drapes_length: params[:drapes_length], 
                
                
                # bookcase_small: params[:bookcase_small],
                # bookcase_medium: params[:bookcase_medium],
                # bookcase_large: params[:bookcase_large],
                # media_small: params[:media_small],
                # media_medium: params[:media_medium],
                # media_large: params[:media_large],
               
                
                # dining_chair_small: params[:dining_chair_small],
                # dining_chair_medium: params[:dining_chair_medium],
                # dining_chair_large: params[:dining_chair_large],
                # tent_small: params[:tent_small],
                # tent_medium: params[:tent_medium],
                # tent_large: params[:tent_large],
                sofa_small: params[:sofa_small],
                sofa_medium: params[:sofa_medium],
                sofa_large: params[:sofa_large],
                love_seat_small: params[:love_seat_small], 
                love_seat_medium: params[:love_seat_medium],
                love_seat_large: params[:love_seat_large],
                # sectional_small: params[:sectional_small], 
                # sectional_medium: params[:sectional_medium],
                # sectional_large: params[:sectional_large],
                # bar_stool_small: params[:bar_stool_small], 
                # bar_stool_medium: params[:bar_stool_medium],
                # bar_stool_large: params[:bar_stool_large],
               
                
                # chest_cabinet_small: params[:chest_cabinet_small], 
                # chest_cabinet_medium: params[:chest_cabinet_medium],
                # chest_cabinet_large: params[:chest_cabinet_large],
                chair_small: params[:chair_small], 
                chair_medium: params[:chair_medium],
                chair_large: params[:chair_large],
                # table_small: params[:table_small], 
                # table_medium: params[:table_medium],
                # table_large: params[:table_large],
                # cabinet_small: params[:cabinet_small],
                # cabinet_medium: params[:cabinet_medium],
                # cabinet_large: params[:cabinet_large],
                # console_small: params[:console_small], 
                # console_medium: params[:console_medium],
                # console_large: params[:console_large],
                # plant_tree_small: params[:plant_tree_small],
                # plant_tree_medium: params[:plant_tree_medium],
                # plant_tree_large: params[:plant_tree_large],
                # bar_cart_small: params[:bar_cart_small],
                # bar_cart_medium: params[:bar_cart_medium],
                # bar_cart_large: params[:bar_cart_large],
                # bar_stool_small: params[:bar_stool_small],
                # bar_stool_medium: params[:bar_stool_medium],
                # bar_stool_large: params[:bar_stool_large],
                armchair_small: params[:armchair_small],
                armchair_medium: params[:armchair_medium],
                armchair_large: params[:armchair_large],
                side_small: params[:side_small],
                side_medium: params[:side_medium],
                side_large: params[:side_large],
                cofee_ottoman_small: params[:cofee_ottoman_small], 
                cofee_ottoman_medium: params[:cofee_ottoman_medium],
                cofee_ottoman_large: params[:cofee_ottoman_large],
                dining_table_small: params[:dining_table_small],
                dining_table_medium: params[:dining_table_medium],
                dining_table_large: params[:game_table_large],
                dining_chair_small: params[:dining_chair_small],
                dining_chair_medium: params[:dining_chair_medium],
                dining_chair_large: params[:dining_chair_large],
                firepit_small: params[:firepit_small], 
                firepit_medium: params[:firepit_medium],
                firepit_large: params[:firepit_large],
                bistro_small: params[:bistro_small], 
                bistro_medium: params[:bistro_medium],
                bistro_large: params[:bistro_large],

                notes: params[:notes],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step6: step6)
               redirect_to "/project_walk_through/step7?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step6
               return
            end         
        else
            render :step6
            return
        end        
    end

    def step7
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step7) if project_walk_through.step7.present?
            @id = params[:id]
        end
    end

    def create_step7
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step7)[:images] unless project.step7.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end 

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step7 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                needs: params[:needs], 
                good: params[:good],
                drapes_length: params[:drapes_length], 
                sofa_small: params[:sofa_small],
                sofa_medium: params[:sofa_medium],
                sofa_large: params[:sofa_large],
                love_seat_small: params[:love_seat_small], 
                love_seat_medium: params[:love_seat_medium],
                love_seat_large: params[:love_seat_large],
                sectional_small: params[:sectional_small], 
                sectional_medium: params[:sectional_medium],
                sectional_large: params[:sectional_large],
                armchair_small: params[:armchair_small],
                armchair_medium: params[:armchair_medium],
                armchair_large: params[:armchair_large],
                bench_small: params[:bench_small],
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],
                cofee_ottoman_small: params[:cofee_ottoman_small], 
                cofee_ottoman_medium: params[:cofee_ottoman_medium],
                cofee_ottoman_large: params[:cofee_ottoman_large],
                side_table_small: params[:side_table_small], 
                side_table_medium: params[:side_table_medium],
                side_table_large: params[:side_table_large],
                console_small: params[:console_small], 
                console_medium: params[:console_medium],
                console_large: params[:console_large],
                chest_cabinet_small: params[:chest_cabinet_small], 
                chest_cabinet_medium: params[:chest_cabinet_medium],
                chest_cabinet_large: params[:chest_cabinet_large],
                plant: params[:plant],
                tree: params[:tree],
                bookcase_small: params[:bookcase_small],
                bookcase_medium: params[:bookcase_medium],
                bookcase_large: params[:bookcase_large],
                media_small: params[:media_small],
                media_medium: params[:media_medium],
                media_large: params[:media_large],
                floor_lamp_small: params[:floor_lamp_small],
                floor_lamp_medium: params[:floor_lamp_medium],
                floor_lamp_large: params[:floor_lamp_large],
                game_table_small: params[:game_table_small],
                game_table_medium: params[:game_table_medium],
                game_table_large: params[:game_table_large],
                dining_chair_small: params[:dining_chair_small],
                dining_chair_medium: params[:dining_chair_medium],
                dining_chair_large: params[:dining_chair_large],
                tent_small: params[:tent_small],
                tent_medium: params[:tent_medium],
                tent_large: params[:tent_large],
                notes: params[:notes],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step7: step7)
               redirect_to "/project_walk_through/step8?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step7
               return
            end         
        else
            render :step7
            return
        end        
    end

    def step8
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step8) if project_walk_through.step8.present?
            @id = params[:id]
        end
    end

    def create_step8
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step8)[:images] unless project.step8.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end 

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step8 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                curtain_yes: params[:curtain_yes],
                curtain_no: params[:curtain_no], 
                rod_yes: params[:rod_yes],
                rod_no: params[:rod_no],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                cabinets: params[:cabinets], 
                counterops: params[:counterops],
                skins: params[:skins], 
                bath_towels: params[:bath_towels], 
                hand_towels: params[:hand_towels], 
                bench_small: params[:bench_small],
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],
                
                stool_small: params[:stool_small],
                stool_medium: params[:stool_medium],
                stool_large: params[:stool_large],
                notes: params[:notes],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step8: step8)
               redirect_to "/project_walk_through/step9?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step8
               return
            end         
        else
            render :step8
            return
        end        
    end

    def step9
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step9) if project_walk_through.step9.present?
            @id = params[:id]
        end
    end

    def create_step9
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step9)[:images] unless project.step9.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end 

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step9 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                needs: params[:needs], 
                good: params[:good],
                drapes_length: params[:drapes_length],  
                desk_small: params[:desk_small],
                desk_medium: params[:desk_medium],
                desk_large: params[:desk_large],                
                desk_chair_small: params[:desk_chair_small],
                desk_chair_medium: params[:desk_chair_medium],
                desk_chair_large: params[:desk_chair_large],
                bookcase_small: params[:bookcase_small],
                bookcase_medium: params[:bookcase_medium],
                bookcase_large: params[:bookcase_large],
                love_seat_small: params[:love_seat_small], 
                love_seat_medium: params[:love_seat_medium],
                love_seat_large: params[:love_seat_large],               
                armchair_small: params[:armchair_small],
                armchair_medium: params[:armchair_medium],
                armchair_large: params[:armchair_large],
                bench_small: params[:bench_small],
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],                
                console_small: params[:console_small], 
                console_medium: params[:console_medium],
                console_large: params[:console_large],                
                plant: params[:plant],
                tree: params[:tree],
                side_table_small: params[:side_table_small], 
                side_table_medium: params[:side_table_medium],
                side_table_large: params[:side_table_large],
                floor_lamp_small: params[:floor_lamp_small],
                floor_lamp_medium: params[:floor_lamp_medium],
                floor_lamp_large: params[:floor_lamp_large], 
                notes: params[:notes],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step9: step9)
               redirect_to "/project_walk_through/step10?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step9
               return
            end         
        else
            render :step9
            return
        end        
    end

    def step10
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step10) if project_walk_through.step10.present?
            @id = params[:id]
        end
    end

    def create_step10
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step10)[:images] unless project.step10.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end 

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step10 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                needs: params[:needs], 
                good: params[:good],
                drapes_length: params[:drapes_length],  
                yoga_mats_small: params[:yoga_mats_small],
                yoga_mats_medium: params[:yoga_mats_medium],
                yoga_mats_large: params[:yoga_mats_large],                
                armchair_small: params[:armchair_small],
                armchair_medium: params[:armchair_medium],
                armchair_large: params[:armchair_large],
                bench_small: params[:bench_small],
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],                
                console_small: params[:console_small], 
                console_medium: params[:console_medium],
                console_large: params[:console_large],                
                plant: params[:plant],
                tree: params[:tree],                
                side_table_small: params[:side_table_small], 
                side_table_medium: params[:side_table_medium],
                side_table_large: params[:side_table_large],
                cabinet_cart_small: params[:cabinet_cart_small],
                cabinet_cart_medium: params[:cabinet_cart_medium],
                cabinet_cart_large: params[:cabinet_cart_large], 
                notes: params[:notes],
                tv: params[:tv],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step10: step10)
               redirect_to "/project_walk_through/step11?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step10
               return
            end         
        else
            render :step10
            return
        end        
    end

    def step11
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step11) if project_walk_through.step11.present?
            @id = params[:id]
        end
    end

    def create_step11
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step11)[:images] unless project.step11.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end  
        if project.present?
          
            
            if params[:files].present?
                # errors << 'Photo too large. Max size is 4 MB.' unless params[:img].size <= 4.megabyte
    
                
                params[:files].each do |file|
                    # unless errors.any?
                        new_filename = "#{current_user.username}_#{Time.zone.now.to_i}_#{file.original_filename}"
                        s3_bucket = 'sdn-content'
        
                        # Perform the upload
                        upload_success = $AWS.s3.upload(
                            file.tempfile,
                            bucket: s3_bucket,
                            as: new_filename,
                        )
            
                        if upload_success
                            # Generate the file URL
                            file_url = $AWS.s3.public_url_for(new_filename, bucket: s3_bucket)
                            puts file_url.inspect+"QQQQQQQQQQQQQQQQQQQQQQ"
                            new_urls << file_url
                        else
                            errors << 'Error uploading photo.'
                        end
        
                        
                    # end
                end  
                puts 'received your file. now move to the next step'  
            end

            
                need_to_retain.each do |img_url| 
                    need_to_retain_urls << img_url
                end  if need_to_retain.present? && need_to_retain.size > 0

                if params['remove_existing_images'].any?
                    all_urls = new_urls + need_to_retain_urls
                else
                    all_urls = new_urls + old_urls
                end
            
            step11 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                needs: params[:needs], 
                good: params[:good],
                drapes_length: params[:drapes_length], 
                console_small: params[:console_small], 
                console_medium: params[:console_medium],
                console_large: params[:console_large],
                bookcase_small: params[:bookcase_small],
                bookcase_medium: params[:bookcase_medium],
                bookcase_large: params[:bookcase_large],
                media_small: params[:media_small],
                media_medium: params[:media_medium],
                media_large: params[:media_large],
                floor_lamp_small: params[:floor_lamp_small],
                floor_lamp_medium: params[:floor_lamp_medium],
                floor_lamp_large: params[:floor_lamp_large],
                game_table_small: params[:game_table_small],
                game_table_medium: params[:game_table_medium],
                game_table_large: params[:game_table_large],
                dining_chair_small: params[:dining_chair_small],
                dining_chair_medium: params[:dining_chair_medium],
                dining_chair_large: params[:dining_chair_large],
                tent_small: params[:tent_small],
                tent_medium: params[:tent_medium],
                tent_large: params[:tent_large],
                sofa_small: params[:sofa_small],
                sofa_medium: params[:sofa_medium],
                sofa_large: params[:sofa_large],
                love_seat_small: params[:love_seat_small], 
                love_seat_medium: params[:love_seat_medium],
                love_seat_large: params[:love_seat_large],
                sectional_small: params[:sectional_small], 
                sectional_medium: params[:sectional_medium],
                sectional_large: params[:sectional_large],
                bench_small: params[:bench_small], 
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],
                cofee_ottoman_small: params[:cofee_ottoman_small], 
                cofee_ottoman_medium: params[:cofee_ottoman_medium],
                cofee_ottoman_large: params[:cofee_ottoman_large],
                bench_small: params[:bench_small], 
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],
                side_table_small: params[:side_table_small], 
                side_table_medium: params[:side_table_medium],
                side_table_large: params[:side_table_large],
                chest_cabinet_small: params[:chest_cabinet_small], 
                chest_cabinet_medium: params[:chest_cabinet_medium],
                chest_cabinet_large: params[:chest_cabinet_large],
                cabinet_small: params[:cabinet_small],
                cabinet_medium: params[:cabinet_medium],
                cabinet_large: params[:cabinet_large],
                armchair_small: params[:armchair_small],
                armchair_medium: params[:armchair_medium],
                armchair_large: params[:armchair_large],
                plant: params[:plant],
                tree: params[:tree],                
                bench_small: params[:bench_small],
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],
                notes: params[:notes],
                tv: params[:tv],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step11: step11)
               redirect_to "/project_walk_through/step12?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step11
               return
            end         
        else
            render :step11
            return
        end        
    end

    def step12
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step12) if project_walk_through.step12.present?
            @id = params[:id]
        end
    end

    def create_step12
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step12)[:images] unless project.step12.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end 

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step12 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                cabinets: params[:cabinets], 
                counterops: params[:counterops],
                skins: params[:skins], 
                curtain_yes: params[:curtain_yes],
                curtain_no: params[:curtain_no], 
                rod_yes: params[:rod_yes],
                rod_no: params[:rod_no],
                bath_towels: params[:bath_towels], 
                hand_towels: params[:hand_towels], 
                bench_small: params[:bench_small],
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],                
                stool_small: params[:stool_small],
                stool_medium: params[:stool_medium],
                stool_large: params[:stool_large],
                notes: params[:notes],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step12: step12)
               redirect_to "/project_walk_through/step13?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step12
               return
            end         
        else
            render :step12
            return
        end        
    end

    def step13
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step13) if project_walk_through.step13.present?
            @id = params[:id]
        end
    end

    def create_step13
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step13)[:images] unless project.step13.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end 

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step13 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                needs: params[:needs], 
                good: params[:good],
                drapes_length: params[:drapes_length],  
                yoga_mats_small: params[:yoga_mats_small],
                yoga_mats_medium: params[:yoga_mats_medium],
                yoga_mats_large: params[:yoga_mats_large],                
                armchair_small: params[:armchair_small],
                armchair_medium: params[:armchair_medium],
                armchair_large: params[:armchair_large],
                bench_small: params[:bench_small],
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],                
                console_small: params[:console_small], 
                console_medium: params[:console_medium],
                console_large: params[:console_large],                
                plant: params[:plant],
                tree: params[:tree],                
                side_table_small: params[:side_table_small], 
                side_table_medium: params[:side_table_medium],
                side_table_large: params[:side_table_large],
                cabinet_cart_small: params[:cabinet_cart_small],
                cabinet_cart_medium: params[:cabinet_cart_medium],
                cabinet_cart_large: params[:cabinet_cart_large], 
                notes: params[:notes],
                desk_chair_small: params[:desk_chair_small],
                desk_chair_medium: params[:desk_chair_medium],
                desk_chair_large: params[:desk_chair_large],
                tv: params[:tv],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step13: step13)
               redirect_to "/project_walk_through/step14?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step13
               return
            end         
        else
            render :step13
            return
        end        
    end

    def step14
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step14) if project_walk_through.step14.present?
            @id = params[:id]
        end
    end

    def create_step14
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step14)[:images] unless project.step14.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end 

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step14 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                needs: params[:needs], 
                good: params[:good],
                drapes_length: params[:drapes_length],  
                bed_small: params[:bed_small],
                bed_medium: params[:bed_medium],
                bed_large: params[:bed_large],
                mattress_small: params[:mattress_small],
                mattress_medium: params[:mattress_medium],
                mattress_large: params[:mattress_large],
                box_small: params[:box_small],
                box_medium: params[:box_medium],
                box_large: params[:box_large],
                riser_small: params[:riser_small],
                riser_medium: params[:riser_medium],
                riser_large: params[:riser_large],
                nightboard_small: params[:nightboard_small],
                nightboard_medium: params[:nightboard_medium],
                nightboard_large: params[:nightboard_large],                
                dresser_small: params[:dresser_small],
                dresser_medium: params[:dresser_medium],
                dresser_large: params[:dresser_large],
                bench_small: params[:bench_small],
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],
                armchair_small: params[:armchair_small],
                armchair_medium: params[:armchair_medium],
                armchair_large: params[:armchair_large],
                headboard_small: params[:headboard_small],
                headboard_medium: params[:headboard_medium],
                headboard_large: params[:headboard_large_large],                                
                plant: params[:plant],
                tree: params[:tree],                
                side_table_small: params[:side_table_small], 
                side_table_medium: params[:side_table_medium],
                side_table_large: params[:side_table_large],
                chest_cabinet_small: params[:chest_cabinet_small], 
                chest_cabinet_medium: params[:chest_cabinet_medium],
                chest_cabinet_large: params[:chest_cabinet_large],
                floor_lamp_small: params[:floor_lamp_small],
                floor_lamp_medium: params[:floor_lamp_medium],
                floor_lamp_large: params[:floor_lamp_large],
                love_seat_small: params[:love_seat_small], 
                love_seat_medium: params[:love_seat_medium],
                love_seat_large: params[:love_seat_large],
                notes: params[:notes],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step14: step14)
               redirect_to "/project_walk_through/step15?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step14
               return
            end         
        else
            render :step14
            return
        end        
    end

    def step15
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step15) if project_walk_through.step15.present?
            @id = params[:id]
        end
    end

    def create_step15
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step15)[:images] unless project.step15.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end 

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step15 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                cabinets: params[:cabinets], 
                counterops: params[:counterops],
                skins: params[:skins], 
                curtain_yes: params[:curtain_yes],
                curtain_no: params[:curtain_no], 
                rod_yes: params[:rod_yes],
                rod_no: params[:rod_no],
                bath_towels: params[:bath_towels], 
                hand_towels: params[:hand_towels], 
                bench_small: params[:bench_small],
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],                
                stool_small: params[:stool_small],
                stool_medium: params[:stool_medium],
                stool_large: params[:stool_large],
                notes: params[:notes],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step15: step15)
               redirect_to "/project_walk_through/step16?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step15
               return
            end         
        else
            render :step15
            return
        end        
    end

    def step16
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step16) if project_walk_through.step16.present?
            @id = params[:id]
        end
    end

    def create_step16
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step16)[:images] unless project.step16.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end 

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step16 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                needs: params[:needs], 
                good: params[:good],
                drapes_length: params[:drapes_length],  
                yoga_mats_small: params[:yoga_mats_small],
                yoga_mats_medium: params[:yoga_mats_medium],
                yoga_mats_large: params[:yoga_mats_large],                
                armchair_small: params[:armchair_small],
                armchair_medium: params[:armchair_medium],
                armchair_large: params[:armchair_large],
                bench_small: params[:bench_small],
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],                
                console_small: params[:console_small], 
                console_medium: params[:console_medium],
                console_large: params[:console_large],                
                plant: params[:plant],
                tree: params[:tree],                
                side_table_small: params[:side_table_small], 
                side_table_medium: params[:side_table_medium],
                side_table_large: params[:side_table_large],
                cabinet_cart_small: params[:cabinet_cart_small],
                cabinet_cart_medium: params[:cabinet_cart_medium],
                cabinet_cart_large: params[:cabinet_cart_large], 
                notes: params[:notes],
                tv: params[:tv],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step16: step16)
               redirect_to "/project_walk_through/step17?id=#{project.id}"
            #    redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step16
               return
            end         
        else
            render :step16
            return
        end        
    end



    def step17
        if params[:id].present?
            project_walk_through = ProjectWalkThrough.find(params[:id])
            @project_walk_through = eval(project_walk_through.step17) if project_walk_through.step17.present?
            @id = params[:id]
        end
    end

    def create_step17
        all_urls, new_urls, need_to_retain_urls, project = intialize_files_and_project
        old_urls = eval(project.step17)[:images] unless project.step17.nil?

        if params['remove_existing_images'].any?
          urls = params['remove_existing_images'][0].gsub(/^\[|\]$/, '').split(',')
          deleted_urls = urls.reject!(&:empty?)
          need_to_retain = old_urls.to_a - deleted_urls.to_a
        end 

        if project.present?
            errors = []
            images_url = []            
            all_urls = handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)  

            step17 = {
                standard: params[:standard], 
                luxury: params[:luxury], 
                owner: params[:owner],
                design_staging: params[:design_staging], 
                small: params[:small], 
                medium: params[:medium], 
                large: params[:large], 
                xl: params[:xl],
                xxl: params[:xxl],
                xxxl: params[:xxxl],
                five_by_seven: params[:five_by_seven], 
                six_by_eight: params[:six_by_eight], 
                seven_by_nine: params[:seven_by_nine], 
                eight_by_ten: params[:eight_by_ten],
                other: params[:other],
                built_in: params[:built_in], 
                realtor_request: params[:realtor_request], 
                floor: params[:floor],
                room: params[:room], 
                mirror: params[:mirror], 
                wall_color: params[:wall_color],
                floor_color: params[:floor_color], 
                cabinets: params[:cabinets], 
                counterops: params[:counterops],
                skins: params[:skins], 
                curtain_yes: params[:curtain_yes],
                curtain_no: params[:curtain_no], 
                rod_yes: params[:rod_yes],
                rod_no: params[:rod_no],
                bath_towels: params[:bath_towels], 
                hand_towels: params[:hand_towels], 
                bench_small: params[:bench_small],
                bench_medium: params[:bench_medium],
                bench_large: params[:bench_large],                
                stool_small: params[:stool_small],
                stool_medium: params[:stool_medium],
                stool_large: params[:stool_large],
                notes: params[:notes],
                images: all_urls
                # Adding this as it was in the original JSON string
            }

            if project.update(step17: step17)
                GenerateProjectPdfJob.perform_later(project.id)
            #    redirect_to "/project_walk_through/step15?id=#{project.id}"
               redirect_to "/account/orders/#{project&.order&.id}", notice: "PDF generated."
            else
               render :step17
               return
            end         
        else
            render :step17
            return
        end        
    end

    def download
        filename = params[:filename]
        filepath = Rails.root.join('public', 'pdfs', "#{filename}.pdf")
    
        if File.exist?(filepath)
          send_file(filepath, filename: filename, type: 'application/pdf', disposition: 'attachment')
        else
          render plain: 'File not found', status: :not_found
        end
    end

    private

    def intialize_files_and_project
        all_urls = []
        new_urls = []
        need_to_retain_urls = []
        project = ProjectWalkThrough.find(params[:project_walk_through_id])
        [all_urls, new_urls, need_to_retain_urls, project]
    end
    
    def handle_images(new_urls, old_urls, need_to_retain_urls, errors, need_to_retain, all_urls)
        if params[:files].present?
            params[:files].each do |file|                
                new_filename = "#{current_user.username}_#{Time.zone.now.to_i}_#{file.original_filename}"
                s3_bucket = 'sdn-content'
                # Perform the upload
                upload_success = $AWS.s3.upload(
                    file.tempfile,
                    bucket: s3_bucket,
                    as: new_filename,
                )    
                if upload_success
                    # Generate the file URL
                    file_url = $AWS.s3.public_url_for(new_filename, bucket: s3_bucket)
                    puts file_url.inspect+"QQQQQQQQQQQQQQQQQQQQQQ"
                    new_urls << file_url
                else
                    errors << 'Error uploading photo.'
                end   
            end  
            puts 'received your file. now move to the next step'  
        end

        need_to_retain.each do |img_url| 
            need_to_retain_urls << img_url
        end  if need_to_retain.present? && need_to_retain.size > 0

        if params['remove_existing_images'].any?
            all_urls = new_urls + need_to_retain_urls
        else
            all_urls = new_urls + old_urls
        end
    end
end
