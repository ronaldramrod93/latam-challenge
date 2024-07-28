def build_query(columns, gcp_project, dataset, table):
    return f"SELECT {columns} FROM `{gcp_project}.{dataset}.{table}` LIMIT 10"


def parse_to_json(results):
    data = []
    for row in results:
        data.append(dict(row))
    return data
