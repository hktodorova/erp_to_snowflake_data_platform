install:
	pip install -r requirements.txt

data:
	python scripts/generate_sample_data.py

test:
	pytest -q

smoke:
	python tests/smoke_test_project.py

# Fully local recruiter/demo workflow.
# Creates an isolated demo virtualenv, installs only lightweight local dependencies,
# generates sample ERP data, runs local data-quality checks, smoke checks and pytest.
demo:
	python -m venv .venv-demo
	. .venv-demo/bin/activate && python -m pip install --upgrade pip && python -m pip install -r requirements-demo.txt
	. .venv-demo/bin/activate && python scripts/generate_sample_data.py && python snowpark/data_quality_local_demo.py && python tests/smoke_test_project.py && python -m pytest -q
	@echo "Local demo completed successfully: sample data, quality checks, smoke checks and pytest passed."

dbt-parse:
	cd dbt && dbt deps && dbt parse --profiles-dir .

lint-sql:
	sqlfluff lint sql --dialect snowflake
	sqlfluff lint dbt/models --dialect snowflake

terraform-validate:
	cd terraform && terraform init -backend=false && terraform validate

contract-test:
	pytest -q tests/test_contract_alignment.py tests/test_static_dbt_project.py

clean:
	rm -rf .pytest_cache dbt/target dbt/dbt_packages dbt/logs logs .terraform .venv-demo .coverage htmlcov
	find . -type d -name __pycache__ -prune -exec rm -rf {} +

package: clean
	zip -r erp_to_snowflake_data_platform_clean.zip . -x ".env" "*.env" ".venv/*" ".venv-demo/*" "*/__pycache__/*" "dbt/target/*" "dbt/logs/*" "dbt/dbt_packages/*" ".pytest_cache/*"

ci-local: clean smoke test contract-test
	@echo "Local CI checks passed"
