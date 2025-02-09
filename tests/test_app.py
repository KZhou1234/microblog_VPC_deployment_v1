import pytest

from app import create_app

@pytest.fixture()
def app():
        app = create_app()
        app.config.update({
                "TESTING": True,
        })

        yield app

@pytest.fixture()
def client(app):
        return app.test_client()

def test_login(client):
        assert client
        response = client.get('/login')
        print(response)
        assert response.status_code == 200
        
def test_homepage(client):
        assert client
        response = client.get('/')
        print(response)
        assert response.status_code == 302
#login required
