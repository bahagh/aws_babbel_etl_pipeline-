# integration tests should be here :) #
import pytest

@pytest.fixture
def test_pass():
############################
    assert len('baha')==4
############################
