query_templates = {
    datasets = [[
        select
                #columns_list#
        from
            dataset d
        left outer join
            funder_ds_map fdm
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
                    funder_ds_map
                #funder_id_filter_clause#
            )
        and
            d.dataset_id in (
                select
                    dataset_id
                from
                    inst_ds_map
                where
                    inst_id = #inst_id#
            )
        )
        #arch_status_filter_clause#
        #date_filter_clause#
        #dataset_filter_clause#
        #location_filter_clause#
        #faculty_filter_clause#
        #dept_filter_clause#
        #project_filter_clause#
        #order_clause#
        ;
    ]]
}

columns_lists = {
    datasets = [[
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
    datasets_count = [[
        count(*) num_datasets
    ]]
}