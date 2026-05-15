pip install -r requirements.txt
cd dbt
dbt deps
dbt parse
dbt test
cd ..
pytest