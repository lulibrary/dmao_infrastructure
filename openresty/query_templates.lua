
query_templates = {
    datasets = {
        columns_list = [[
            f.funder_id,
            f.name funder_name,
            d.*,
            fac.abbreviation lead_faculty_abbrev,
            fac.name lead_faculty_name,
            dept.abbreviation lead_dept_abbrev,
            dept.name lead_dept_name,
            p.project_awarded,
            p.project_start,
            p.project_end,
            p.project_name
        ]],
        group_by = '',
        output_order = 'order by d.dataset_id asc',
        columns_list_count = [[
            count(*) num_datasets
        ]],
        variable_clauses = {
            dataset_id = 'and d.dataset_id = #el_var_value#',
            date = [[
                and
                (
                    p.#var_value# >= #el_sd# and p.#var_value# <= #el_ed#
                )
                #project_null_dates#
            ]],
            faculty = 'and d.lead_faculty_id = #el_var_value#',
            dept = 'and d.lead_department_id = #el_var_value#',
            project = 'and d.project_id = #el_var_value#',
            arch_status = 'and d.inst_archive_status = #el_var_value#',
            location = 'and d.storage_location = #el_var_value#',
            filter = [[
                where funder_id in (
                select funder_id from funder
                    where is_rcuk_funder = true
                )
            ]]
        },
        query = [[
            select
                #columns_list#
            from
                dataset d
            left outer join
                map_funder_ds fdm
            on
                (d.dataset_id = fdm.dataset_id)
            left outer join
                funder f
            on
                (fdm.funder_id = f.funder_id)
            left outer join
                faculty fac
            on
                (d.lead_faculty_id = fac.faculty_id)
            left outer join
                department dept
            on
                (d.lead_department_id = dept.department_id)
            left outer join
                project p
            on
                (d.project_id = p.project_id)
            where (
                d.dataset_id in (
                    select
                        dataset_id
                    from
                        map_funder_ds
                    #funder_id_filter_clause#
                )
            and
                d.dataset_id in (
                    select
                        dataset_id
                    from
                        map_inst_ds
                    where
                        inst_id = #inst_id#
                )
            )
            #variable_clauses#
            #group_by_clause#
            #order_clause#
        ]],
    },
    project_dmps = {
        columns_list = [[
            p.*,
            f.abbreviation lead_faculty_abbrev,
            f.name lead_faculty_name,
            d.abbreviation lead_dept_abbrev,
            d.name lead_dept_name
        ]],
        group_by = '',
        output_order = 'order by p.project_id asc',
        columns_list_count = [[
            count(*) num_project_dmps
        ]],
        variable_clauses = {
            project_id = 'and d.project_id = #el_var_value#',
            date = [[
                and
                (
                    p.#var_value# >= #el_sd# and p.#var_value# <= #el_ed#
                )
            ]],
            faculty = 'and p.lead_faculty_id = #el_var_value#',
            dept = 'and p.lead_department_id = #el_var_value#',
            has_dmp = 'and #not# p.has_dmp',
            dmp_reviewed = 'and p.has_dmp_been_reviewed = #el_var_value#',
            is_awarded = 'and #not# d.is_awarded'
        },
        query = [[
            select
                #columns_list#
            from
                project p
            join
                faculty f
            on
                (p.lead_faculty_id = f.faculty_id)
            join
                department d
            on
                (p.lead_department_id = d.department_id)
            where
                p.inst_id = #inst_id#
            #variable_clauses#
            #group_by_clause#
            #order_clause#
        ]]
    },
    dmp_status = {
        columns_list = [[
            p.*,
            fpm.funder_id funder_id,
            dmp.dmp_ss_pid dmp_source_system_id,
            dmp.dmp_state,
            dmp.dmp_status
        ]],
        output_order = 'order by p.project_id asc',
        columns_list_count = [[
            count(*) num_dmp_status
        ]],
        variable_clauses = {
            project = 'and p.project_id = #el_var_value#',
            date = [[
                and
                (
                    p.#var_value# >= #el_sd# and p.#var_value# <= #el_ed#
                )
                #project_null_dates#
            ]],
            faculty = 'and d.lead_faculty_id = #el_var_value#',
            dept = 'and d.lead_department_id = #el_var_value#',
            dmp_state = 'and dmp.state = #el_var_value#',
            dmp_status = 'and dmp.status = #el_var_value#',
            has_dmp = 'and #not# p.has_dmp',
            dmp_reviewed = 'and p.has_dmp_been_reviewed = #el_var_value#',
        },
        query = [[
            select
                #columns_list#
            from
                project p
            left outer join
                map_funder_project fpm
            on
                (p.project_id = fpm.project_id)
            left outer join
                dmp
            on
                (p.dmp_id = dmp.dmp_id)
            where
                p.inst_id = #inst_id#
            #variable_clauses#
            #group_by_clause#
            #order_clause#
        ]]
    },
    storage = {
        columns_list = [[
            p.project_id,
            p.project_awarded,
            p.project_start,
            p.project_end,
            p.project_name,
            p.lead_faculty_id,
            p.lead_department_id,
            sum(pes.expected_storage) expected_storage,
            d.dataset_id,
            d.dataset_pid,
            d.dataset_size
        ]],
        output_order = 'order by p.project_id asc, d.dataset_id asc',
        group_by = 'group by p.project_id, d.dataset_id',
        columns_list_count = [[
            count(*) num_expected_storage
        ]],
        variable_clauses = {
            project = 'and p.project_id = #el_var_value#',
            faculty = 'and p.lead_faculty_id = #el_var_value#',
            dept = 'and p.lead_department_id = #el_var_value#',
            dataset_id = 'and d.dataset_id = #el_var_value#',
            date = [[
                and
                (
                    p.#var_value# >= #el_sd# and p.#var_value# <= #el_ed#
                )
            ]],
        },
        query = [[
        select
                #columns_list#
            from
                project p
            left outer join
                dataset d
            on
                (p.project_id = d.project_id)
            join
                project_expected_storage pes
            on
                (p.project_id = pes.project_id)
            where
                p.inst_id = #inst_id#
            #variable_clauses#
            #group_by_clause#
            #order_clause#
        ]]
    },
    rcuk_as = {
        columns_list = [[
            pub.*,
            fpm.funder_id,
            f.name funder_name,
            proj.project_name,
            proj.project_awarded,
            proj.project_start,
            proj.project_end
        ]],
        output_order = 'order by pup.publication_id asc',
        columns_list_count = [[
            count(*) num_pubs
        ]],
        variable_clauses = {
            project = 'and pub.project_id = #el_var_value#',
            date = [[
                and
                (
                    #var_value# >= #el_sd# and #var_value# <= #el_ed#
                )
            ]],
            faculty = 'and d.lead_faculty_id = #el_var_value#',
            dept = 'and d.lead_department_id = #el_var_value#',
            funder_code = 'and pub.funder_project_code = #el_var_value#',
            funder = 'and fpm.funder_id = #el_var_value#'
        },
        query = [[
            select
                #columns_list#
            from
                publication pub
            join
                map_funder_pub fpm
            on
                (
                    pub.publication_id = fpm.publication_id
                    and
                    pub.lead_inst_id = #inst_id#
                )
            join
                funder f
            on
                (f.funder_id = fpm.funder_id)
            left outer join
                project proj
            on
               (pub.project_id = proj.project_id)
            where
                fpm.funder_id in $rcuk_funder_list
            #variable_clauses#
            #order_clause#
        ]]
    },
    dataset_accesses = {
        columns_list =  '',
        summary_column_1 = 'd.dataset_id,',
        summary_column_2 = 'd.access_date,',
        summary_clause_1 = 'd.access_date, d.counter',
        summary_clause_2 = 'sum(d.counter)',
        group_by_clause_1 = '',
        group_by_clause_2 = 'group by d.dataset_id, d.access_type',
        group_by_clause_3 = 'group by d.access_date, d.access_type',
        output_order_1 = [[
            order by d.access_date, d.dataset_id asc, d.access_type asc
        ]],
        output_order_2 = [[
            order by d.dataset_id, d.access_type asc
        ]],
        output_order_3 = [[
            order by d.access_date, d.access_type asc
        ]],
        dataset_id = 'd.dataset_id = #el_var_value#',
        sd = 'd.access_date >= #el_var_value#',
        ed = 'and d.access_date <= #el_var_value#',
        variable_clauses = {
            faculty = [[
                and d.dataset_id in
                    (
                        select dataset_id
                        from map_dataset_faculty
                        where faculty_id = #el_var_value#
                    )
            ]],
            department = [[
                and d.dataset_id in
                    (
                        select dataset_id
                        from map_dept_ds
                        where department_id = #el_var_value#
                    )
            ]]
        },
        query = [[
            select
                #summary_column#
                d.access_type,
                #summary_clause#
            from
                dataset_accesses d
            where d.dataset_id in (
                select dataset_id from map_inst_ds
                where inst_id = #inst_id#
            )
            #and_clause_1#
            #dataset_id#
            #and_clause_2#
            #date_range#
            #variable_clauses#
            #group_by_clause#
            #order_clause#
        ]]
    },
    -- utility queries for internal use
    u_dmao_faculty_ids_inst_ids_map = {
        query = [[
            select faculty_id, inst_local_id
            from faculty
            where inst_id = #inst_id#
        ]]
    },
    u_dmao_department_ids_faculty_ids_map = {
        query = [[
            select department_id, faculty_id,
            inst_local_id local_faculty_id, name dept_name
            from department
            where inst_id = #inst_id#
        ]]
    },
    u_api_key_for_inst = {
        query = [[
            select api_key from institution
            where inst_id = #inst_id#
        ]]
    }
}
