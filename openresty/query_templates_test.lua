
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
                ((
                    p.#var_value# >= #el_sd# and p.#var_value# <= #el_ed#
                )
                #project_null_dates#)
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
    project_dmps_modifiable = {
        columns_list = '*',
        variable_clauses = {
            modifiable = ''
        },
        group_by = '',
        output_order = '',
        query = [[
            select #columns_list# from project_dmps_view_modifiables
        ]]
    },
    project_dmps = {
        columns_list = [[
            *
        ]],
        group_by = '',
        output_order = 'order by project_id asc',
        columns_list_count = [[
            count(*) num_project_dmps
        ]],
        variable_clauses = {
            project_id = 'and project_id = #el_var_value#',
            date = [[
                and
                (
                    #var_value# >= #el_sd# and #var_value# <= #el_ed#
                )
            ]],
            faculty = 'and lead_faculty_id = #el_var_value#',
            dept = 'and lead_department_id = #el_var_value#',
            has_dmp = 'and #not# has_dmp',
            dmp_reviewed = 'and has_dmp_been_reviewed = #el_var_value#',
            is_awarded = 'and #not# is_awarded'
        },
        query = [[
            select
                #columns_list#
            from
                project_dmps_view
            where
                inst_id = #inst_id#
            #variable_clauses#
            #group_by_clause#
            #order_clause#
        ]],
        put_pkeys = {
            'project_id'
        },
        put_updateable_columns = {
            'dmp_id',
            'has_dmp',
            'has_dmp_been_reviewed'
        },
        put = [[
            update
                project_dmps_view
            set
                #set_dmp_id#
                #set_has_dmp#
                #set_has_dmp_been_reviewed#
            where
                project_id = #project_id#
            and
                inst_id = #inst_id#
            returning *
        ]]
    },
    dmp_status = {
        columns_list = [[
            p.*,
            fpm.funder_id funder_id,
            dmp.dmp_source_system,
            dmp.dmp_ss_pid dmp_source_system_id,
            dmp.dmp_state,
            dmp.dmp_status,
            dmp.author_orcid,
            f.name funder_name,
            fds.funder_id,
            fds.funder_state_code,
            fds.funder_state_name
        ]],
        group_by = '',
        output_order = 'order by p.project_id asc',
        columns_list_count = [[
            count(*) num_dmp_status
        ]],
        variable_clauses = {
            project_id = 'and p.project_id = #el_var_value#',
            date = [[
                and
                ((
                    p.#var_value# >= #el_sd# and p.#var_value# <= #el_ed#
                )
                #project_null_dates#)
            ]],
            faculty = 'and p.lead_faculty_id = #el_var_value#',
            dept = 'and p.lead_department_id = #el_var_value#',
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
            left outer join
                funder_dmp_states fds
            on
                (dmp.dmp_state = fds.dmp_state_id)
            left outer join
                funder f
            on
                (fds.funder_id = f.funder_id)
            where
                p.inst_id = #inst_id#
            #variable_clauses#
            #group_by_clause#
            #order_clause#
        ]]
    },
    storage_modifiable = {
        columns_list = '*',
        variable_clauses = {
            modifiable = ''
        },
        output_order = '',
        group_by = '',
        query = [[
            select #columns_list# from storage_view_modifiables
        ]]
    },
    storage_ispi_list = {
        columns_list = 'ispi, ispn',
        variable_clauses = {
            ispi_list = ''
        },
        output_order = '',
        group_by = '',
        query = [[
            select #columns_list#
            from storage_ispi_list
            where inst_id = #inst_id#
        ]]
    },
    storage = {
        columns_list = [[
            *
        ]],
        output_order = 'order by project_id asc, dataset_id asc',
        group_by = '',
        columns_list_count = [[
            count(*) num_expected_storage
        ]],
        variable_clauses = {
            project_id = 'and project_id = #el_var_value#',
            faculty = 'and lead_faculty_id = #el_var_value#',
            dept = 'and lead_department_id = #el_var_value#',
            dataset_id = 'and dataset_id = #el_var_value#',
            date = [[
                and
                (
                    #var_value# >= #el_sd# and #var_value# <= #el_ed#
                )
            ]],
        },
        query = [[
            select
                #columns_list#
            from
                storage_view
            where
                inst_id = #inst_id#
            #variable_clauses#
            #group_by_clause#
            #order_clause#
        ]],
        put_pkeys = {
            'project_id',
            'inst_storage_platform_id'
        },
        delete_pkeys = {
            'project_id',
            'inst_storage_platform_id'
        },
        put_updateable_columns = {
            'expected_storage'
        },
        put = [[
            update
                storage_view
            set
                #set_expected_storage#
            where
                project_id = #project_id#
            and
                inst_storage_platform_id = #inst_storage_platform_id#
            and
                inst_id = #inst_id#
            returning *
        ]],
        delete = [[
            delete from
                storage_view
            where
                project_id = #project_id#
            and
                inst_storage_platform_id = #inst_storage_platform_id#
            and
                inst_id = #inst_id#
            returning null
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
        output_order = 'order by pub.publication_id asc',
        columns_list_count = [[
            count(*) num_pubs
        ]],
        group_by = '',
        variable_clauses = {
            project_id = 'and pub.project_id = #el_var_value#',
            date = [[
                and
                (
                    #var_value# >= #el_sd# and #var_value# <= #el_ed#
                )
            ]],
            faculty = 'and pub.lead_faculty_id = #el_var_value#',
            dept = 'and pub.lead_department_id = #el_var_value#',
            funder_project_code = 'and pub.funder_project_code = #el_var_value#',
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
                    pub.inst_id = #inst_id#
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
                fpm.funder_id in (
                    'ahrc', 'bbsrc', 'epsrc',
                    'esrc', 'mrc', 'nerc', 'stfc'
                )
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
            dept = [[
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
    },
    -- open queries for summary information and login
    o_inst_list = {
        query = [[
            select inst_id, name from institution
        ]]
    },
    o_get_api_key = {
        query = [[
            select
                api_key
            from
                institution
            where inst_id in
                (
                    select
                        inst_id
                    from
                        users
                    where
                        inst_id = #inst_id#
                    and
                        username = #username#
                    and
                        passwd = #passwd#
                )
        ]]
    },
    o_count_institutions = {
        query = [[
            select count(*) from institution
        ]]
    },
    o_count_faculties = {
        query = [[
            select count(*) from faculty
        ]]
    },
    o_count_departments = {
        query = [[
            select count(*) from department
        ]]
    },
    o_count_dmps = {
        query = [[
            select count(*) from dmp
        ]]
    },
    o_count_publications = {
        query = [[
            select count(*) from publication
        ]]
    },
    o_count_datasets = {
        query = [[
            select count(*) from dataset
        ]]
    },
    o_count_projects = {
        query = [[
            select count(*) from project
        ]]
    },
    o_count_dataset_accesses = {
        query = [[
            select access_type, sum(counter) count
            from dataset_accesses group by access_type
        ]]
    }
}
